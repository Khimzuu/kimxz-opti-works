param(
 [Parameter(Mandatory=$true)][string]$Job,
 [Parameter(Mandatory=$true)][string]$StatusPath
)
$ErrorActionPreference='Stop'
$base=Join-Path $env:LOCALAPPDATA 'kim.xz-opti-works'
$logdir=Join-Path $base 'logs';$backupdir=Join-Path $base 'backups'
New-Item -ItemType Directory -Force -Path $logdir,$backupdir | Out-Null
$log=Join-Path $logdir ('v3-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.log')
$script:finished=0;$script:total=1;$script:errors=@()
function Save-State($state,$message){
 $obj=[pscustomobject]@{state=$state;message=$message;done=$script:finished;total=$script:total;log=$log;timestamp=(Get-Date).ToString('o')}
 $tmp=$StatusPath+'.tmp'; $obj | ConvertTo-Json -Compress | Set-Content -LiteralPath $tmp -Encoding UTF8
 Move-Item -LiteralPath $tmp -Destination $StatusPath -Force
}
function Log($text){ $s='[{0}] {1}' -f (Get-Date -Format 'HH:mm:ss'),$text; Add-Content -LiteralPath $log -Value $s;Save-State 'running' $text }
function Elevated { $p=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent());$p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) }
function Cmd($exe,[string[]]$argsList){
 $output= & $exe @argsList 2>&1 | Out-String
 Add-Content -LiteralPath $log -Value $output
 if($LASTEXITCODE -ne 0){throw "$exe returned exit code $LASTEXITCODE"}
}
function Baseline {
 $f=Join-Path $backupdir 'v3-preferences.json';if(Test-Path $f){return}
 $p=(Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name VisualFXSetting -ErrorAction SilentlyContinue).VisualFXSetting
 $m=(Get-ItemProperty 'HKCU:\Control Panel\Desktop' -Name MenuShowDelay -ErrorAction SilentlyContinue).MenuShowDelay
 $match=[regex]::Match((powercfg.exe /getactivescheme|Out-String),'[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}')
 [pscustomobject]@{visual=$p;menu=$m;power=$(if($match.Success){$match.Value}else{$null})} | ConvertTo-Json | Set-Content -LiteralPath $f -Encoding UTF8
}
function TempClean {
 $cut=(Get-Date).AddDays(-2);$count=0;$skip=0
 foreach($dir in (@($env:TEMP,(Join-Path $env:windir 'Temp')) | Select-Object -Unique)){
  if(!(Test-Path -LiteralPath $dir)){continue}
  if($dir -eq (Join-Path $env:windir 'Temp') -and !(Elevated)){continue}
  Get-ChildItem -LiteralPath $dir -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object {$_.LastWriteTime -lt $cut -and !($_.Attributes -band [IO.FileAttributes]::ReparsePoint)} | ForEach-Object {try{Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop;$count++}catch{$skip++}}
 }
 Log "Removed $count older temp files; skipped $skip locked/protected files"
}
function Preferences {
 Baseline
 $p='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'
 New-Item -Path $p -Force|Out-Null
 New-ItemProperty -Path $p -Name VisualFXSetting -PropertyType DWord -Value 2 -Force|Out-Null
 Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name MenuShowDelay -Value '100'
 Log 'Reduced visual effects preference and menu delay; sign-out may be needed'
}
function RestorePreferences {
 $f=Join-Path $backupdir 'v3-preferences.json';if(!(Test-Path $f)){throw 'No saved baseline found'}
 $b=Get-Content $f -Raw | ConvertFrom-Json
 $p='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'
 if($null -ne $b.visual){New-Item -Path $p -Force|Out-Null;New-ItemProperty -Path $p -Name VisualFXSetting -PropertyType DWord -Value ([int]$b.visual) -Force|Out-Null}else{Remove-ItemProperty $p -Name VisualFXSetting -ErrorAction SilentlyContinue}
 if($null -ne $b.menu){Set-ItemProperty 'HKCU:\Control Panel\Desktop' -Name MenuShowDelay -Value ([string]$b.menu)}
 if($b.power){Cmd 'powercfg.exe' @('/setactive',([string]$b.power))}
 Log 'Restored backed-up preferences where possible'
}
function Execute($task){
 switch($task){
 'temp' {TempClean}
 'dns' {Cmd 'ipconfig.exe' @('/flushdns');Log 'DNS cache flushed'}
 'diskreport' {$drive=Get-PSDrive -Name C;Log ('C: free {0:N1} GB' -f ($drive.Free/1GB))}
 'status' {$os=Get-CimInstance Win32_OperatingSystem;Log ("$($os.Caption), RAM {0:N1} GB" -f ($os.TotalVisibleMemorySize/1MB))}
 'visual' {Preferences}
 'gamemode' {Baseline;New-Item -Path 'HKCU:\Software\Microsoft\GameBar' -Force|Out-Null;New-ItemProperty -Path 'HKCU:\Software\Microsoft\GameBar' -Name AutoGameModeEnabled -PropertyType DWord -Value 1 -Force|Out-Null;Log 'Windows Game Mode user setting enabled'}
 'power' {Baseline;Cmd 'powercfg.exe' @('/setactive','SCHEME_MIN');Log 'High Performance power plan requested; heat/battery use can rise'}
 'revert' {RestorePreferences}
 'sfc' {Cmd 'sfc.exe' @('/scannow');Log 'SFC finished'}
 'dism' {Cmd 'dism.exe' @('/Online','/Cleanup-Image','/RestoreHealth');Log 'DISM finished'}
 'registry' {$p=Join-Path $backupdir ('HKCU-'+(Get-Date -Format 'yyyyMMddHHmmss')+'.reg');Cmd 'reg.exe' @('export','HKCU',$p,'/y');Log "HKCU exported: $p (not a system backup)"}
 'restorepoint' {Checkpoint-Computer -Description 'kim.xz opti works V3' -RestorePointType MODIFY_SETTINGS;Log 'Restore point requested'}
 'recycle' {Clear-RecycleBin -Force;Log 'Recycle Bin emptied permanently'}
 'network' {Cmd 'netsh.exe' @('winsock','reset');Cmd 'netsh.exe' @('int','ip','reset');Log 'Network stack reset; restart required'}
 'driveopt' {Cmd 'defrag.exe' @('C:','/O');Log 'Windows selected drive optimization performed'}
 'defenderstatus' {$s=Get-MpComputerStatus;Log ("Defender real-time protection: $($s.RealTimeProtectionEnabled), tamper protection: $($s.IsTamperProtected)")}
 default {throw "Unknown action $task"}
 }
}
# Presets deliberately exclude network reset, Recycle Bin, Defender disabling, update disabling, and irreversible changes.
$tasks=switch($Job){
 'standard' {@('status','diskreport','temp','dns')}
 'advanced' {@('status','diskreport','temp','dns','visual','gamemode','driveopt','defenderstatus')}
 default {@($Job)}
}
$script:total=$tasks.Count;Save-State 'running' "Starting $Job"
foreach($task in $tasks){
 Log "Starting $task"
 try {Execute $task; Log "Completed $task"}
 catch { $message="$task failed: $($_.Exception.Message)";$script:errors+= $message;Log $message }
 $script:finished++;Save-State 'running' "Finished $task ($script:finished/$script:total)"
}
if($script:errors.Count){Save-State 'partial' ('Completed with '+$script:errors.Count+' issue(s); open log')}else{Save-State 'success' 'All selected actions completed'}
