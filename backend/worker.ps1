param([Parameter(Mandatory=$true)][string]$JobFile)
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$allowed=@('inventory','temp','dns','startup-report','visuals','storage-report','game-mode','power-report','disk-optimize','undo','sfc','dism','restore-point')
$dir=Split-Path -Parent $JobFile
$id=[IO.Path]::GetFileNameWithoutExtension($JobFile)
$eventFile=Join-Path $dir "$id.events.jsonl"
$homeDir=Join-Path $env:LOCALAPPDATA 'kim.xz-opti-works'
$logDir=Join-Path $homeDir 'logs'
$backupDir=Join-Path $homeDir 'backups'
New-Item -ItemType Directory -Force -Path $dir,$logDir,$backupDir | Out-Null
$logFile=Join-Path $logDir "$id.log"
function Emit($operation,$status,$detail){
 $obj=[ordered]@{at=(Get-Date).ToString('o');operation=$operation;status=$status;detail=[string]$detail}
 $line=ConvertTo-Json -InputObject $obj -Compress -Depth 4
 Add-Content -LiteralPath $eventFile -Value $line -Encoding UTF8
 Add-Content -LiteralPath $logFile -Value $line -Encoding UTF8
}
function Execute($file,[string[]]$argv){
 $output= & $file @argv 2>&1 | Out-String
 $code=$LASTEXITCODE
 if($code -ne 0){throw "$file exited $code : $output"}
 return ($output.Trim())
}
function Baseline {
 $file=Join-Path $backupDir 'original-settings.json'
 if(Test-Path $file){return}
 $v=Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -ErrorAction SilentlyContinue
 $desktop=Get-ItemProperty 'HKCU:\Control Panel\Desktop' -ErrorAction SilentlyContinue
 $game=Get-ItemProperty 'HKCU:\Software\Microsoft\GameBar' -ErrorAction SilentlyContinue
 $keys=@{VisualFXSetting=$(if($null -ne $v){$v.VisualFXSetting}else{$null});MenuShowDelay=$(if($null -ne $desktop){$desktop.MenuShowDelay}else{$null});AutoGameModeEnabled=$(if($null -ne $game){$game.AutoGameModeEnabled}else{$null})}
 $keys | ConvertTo-Json | Set-Content -LiteralPath $file -Encoding UTF8
}
function PutValue($key,$name,$value,$type){
 if(!(Test-Path $key)){New-Item -Path $key -Force | Out-Null}
 New-ItemProperty -Path $key -Name $name -Value $value -PropertyType $type -Force | Out-Null
}
function Operation([string]$op){switch($op){
 'inventory' {
  $os=Get-CimInstance Win32_OperatingSystem
  $cpu=Get-CimInstance Win32_Processor | Select-Object -First 1
  $ram=[math]::Round($os.TotalVisibleMemorySize/1MB,1)
  $system=Get-CimInstance Win32_ComputerSystem
  $vol=Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | Select-Object DeviceID,Size,FreeSpace
  $disks=Get-PhysicalDisk -ErrorAction SilentlyContinue | Select-Object FriendlyName,MediaType,Size
  $data=[ordered]@{os=$os.Caption;version=$os.Version;cpu=$cpu.Name;ramGiB=$ram;model=$system.Model;computerType=$system.PCSystemType;volumes=$vol;disks=$disks}
  return (ConvertTo-Json -InputObject $data -Compress -Depth 5)
 }
 'temp' {
  $cut=(Get-Date).AddHours(-24);$removed=0;$skipped=0
  $folder=$env:TEMP
  if(!(Test-Path -LiteralPath $folder)){return 'Temporary folder not found'}
  Get-ChildItem -LiteralPath $folder -File -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {$_.LastWriteTime -lt $cut -and !($_.Attributes -band [IO.FileAttributes]::ReparsePoint)} | ForEach-Object {try{Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop;$removed++}catch{$skipped++}}
  return "Removed $removed older temporary files; $skipped files skipped. User files and recent temp files are not targeted."
 }
 'dns' {return (Execute 'ipconfig.exe' @('/flushdns'))}
 'startup-report' {
  $startup=(Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue | Select-Object -First 25 Name,Location)
  return "Startup entry assessment (nothing disabled): " +(ConvertTo-Json -InputObject @($startup) -Compress)
 }
 'visuals' {
  Baseline
  PutValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 2 'DWord'
  PutValue 'HKCU:\Control Panel\Desktop' 'MenuShowDelay' '100' 'String'
  return 'Visual preference and menu delay applied. Sign out may be required.'
 }
 'game-mode' {
  Baseline;PutValue 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1 'DWord'
  return 'Windows Game Mode user preference enabled (where supported).'
 }
 'storage-report' {
  $vol=Get-Volume -ErrorAction SilentlyContinue | Where-Object {$_.DriveLetter} | Select-Object DriveLetter,FileSystem,Size,SizeRemaining,HealthStatus
  return 'Drive health and capacity (no changes): '+(ConvertTo-Json -InputObject @($vol) -Compress)
 }
 'power-report' {return 'Current power plan (no change): '+(Execute 'powercfg.exe' @('/getactivescheme'))}
 'disk-optimize' {
  $drive=$env:SystemDrive.TrimEnd(':')
  $v=Get-Volume -DriveLetter $drive -ErrorAction Stop
  if($v.FileSystem -ne 'NTFS'){return 'Skipped: system volume is not NTFS.'}
  $r=Optimize-Volume -DriveLetter $drive -Verbose -ErrorAction Stop 4>&1 | Out-String
  return 'Windows Optimize-Volume completed with media-aware defaults: '+$r.Trim()
 }
 'undo' {
  $file=Join-Path $backupDir 'original-settings.json'
  if(!(Test-Path $file)){return 'No prior optimization baseline exists.'}
  $original=Get-Content -LiteralPath $file -Raw | ConvertFrom-Json
  $items=@(@('HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects','VisualFXSetting','DWord',$original.VisualFXSetting),@('HKCU:\Control Panel\Desktop','MenuShowDelay','String',$original.MenuShowDelay),@('HKCU:\Software\Microsoft\GameBar','AutoGameModeEnabled','DWord',$original.AutoGameModeEnabled))
  foreach($item in $items){if($null -eq $item[3]){Remove-ItemProperty -Path $item[0] -Name $item[1] -ErrorAction SilentlyContinue}else{PutValue $item[0] $item[1] $item[3] $item[2]}}
  return 'Stored user preferences restored; baseline preserved.'
 }
 'sfc' {return (Execute 'sfc.exe' @('/scannow'))}
 'dism' {return (Execute 'dism.exe' @('/Online','/Cleanup-Image','/RestoreHealth'))}
 'restore-point' {Checkpoint-Computer -Description 'kim.xz OPTI WORKS V1.04' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop;return 'Windows confirmed restore-point request completed.'}
 default {throw "Unsupported operation: $op"}
}}
try {
 $spec=Get-Content -LiteralPath $JobFile -Raw | ConvertFrom-Json
 $operations=@($spec.operations)
 if($operations.Count -eq 0 -or $operations.Count -gt 15){throw 'Invalid operation count'}
 foreach($op in $operations){if($op -notin $allowed){throw "Operation rejected: $op"}}
 Emit 'job' 'started' "Starting $($operations.Count) operations"
 $failed=0
 foreach($op in $operations){
  Emit $op 'running' 'Executing'
  try{$message=Operation $op;Emit $op 'success' $message}catch{$failed++;Emit $op 'failure' $_.Exception.Message}
 }
 if($failed){Emit 'job' 'failure' "$failed of $($operations.Count) operations failed";exit 2}
 Emit 'job' 'success' "All $($operations.Count) operations completed";exit 0
}catch{Emit 'job' 'failure' $_.Exception.Message;exit 1}
