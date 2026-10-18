# Separate console action runner. Choose actions only through GUI or -Action parameter.
param([ValidateSet('maintenance','temp','dns','recycle','cleanup','sfc','dism','registry','performance','power','undo','restore','network','startup','status')][string]$Action)
$ErrorActionPreference='Continue'
$root=Join-Path $env:LOCALAPPDATA 'kim.xz-opti-works'
$logs=Join-Path $root 'logs';$backups=Join-Path $root 'backups'
New-Item -ItemType Directory -Force -Path $logs,$backups|Out-Null
$log=Join-Path $logs ('gui-{0}.log' -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
function Log([string]$s){$msg='[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),$s;Write-Host $msg;Add-Content -LiteralPath $log -Value $msg}
function Admin{$id=[Security.Principal.WindowsIdentity]::GetCurrent();$p=New-Object Security.Principal.WindowsPrincipal($id);$p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)}
function NeedAdmin{if(Admin){return $true};Log 'Administrator permission required';return $false}
function Cmd([string]$app,[string[]]$argsList){Log ('Running {0} {1}' -f $app,($argsList -join ' '));& $app @argsList 2>&1 | ForEach-Object {Write-Host $_;Add-Content -LiteralPath $log -Value "$_"};Log "Exit code: $LASTEXITCODE"}
function CleanTemp{$cut=(Get-Date).AddDays(-1);foreach($dir in (@($env:TEMP,(Join-Path $env:windir 'Temp'))|Select-Object -Unique)){if(!(Test-Path -LiteralPath $dir)){continue};if($dir -eq (Join-Path $env:windir 'Temp') -and !(Admin)){Log 'Skipping Windows Temp (administrator needed)';continue};$n=0;$skip=0;Get-ChildItem -LiteralPath $dir -File -Recurse -Force -ErrorAction SilentlyContinue|Where-Object {$_.LastWriteTime -lt $cut -and !($_.Attributes -band [IO.FileAttributes]::ReparsePoint)}|ForEach-Object {try {Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop;$n++}catch{$skip++}};Log ("{0}: removed {1}, skipped {2}" -f $dir,$n,$skip)}}
function Original{
 $path=Join-Path $backups 'performance-original.json';if(Test-Path $path){return}
 $v=(Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name VisualFXSetting -ErrorAction SilentlyContinue).VisualFXSetting
 $m=(Get-ItemProperty 'HKCU:\Control Panel\Desktop' -Name MenuShowDelay -ErrorAction SilentlyContinue).MenuShowDelay
 $p=powercfg.exe /getactivescheme|Out-String;$r=[regex]::Match($p,'[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}')
 [pscustomobject]@{visual=$v;menu=$m;power=$(if($r.Success){$r.Value}else{$null})}|ConvertTo-Json|Set-Content -LiteralPath $path
 Log "Original settings backed up: $path"
}
Log "kim.xz opti works v2 action: $Action"
try {switch($Action){
 'maintenance' {CleanTemp;Cmd 'ipconfig.exe' @('/flushdns')}
 'temp' {CleanTemp}
 'dns' {Cmd 'ipconfig.exe' @('/flushdns')}
 'recycle' {Clear-RecycleBin -Force -ErrorAction Stop;Log 'Recycle Bin cleared'}
 'cleanup' {if(Get-Command cleanmgr.exe -ErrorAction SilentlyContinue){Start-Process cleanmgr.exe -Wait}else{Start-Process 'ms-settings:storagesense'}}
 'sfc' {if(NeedAdmin){Cmd 'sfc.exe' @('/scannow')}}
 'dism' {if(NeedAdmin){Cmd 'dism.exe' @('/Online','/Cleanup-Image','/RestoreHealth')}}
 'registry' {$path=Join-Path $backups ('user-registry-{0}.reg' -f (Get-Date -Format 'yyyyMMdd-HHmmss'));Cmd 'reg.exe' @('export','HKCU',$path,'/y');Log "User registry export: $path (not a full backup)"}
 'performance' {Original;$p='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects';New-Item -Path $p -Force|Out-Null;New-ItemProperty -Path $p -Name VisualFXSetting -PropertyType DWord -Value 2 -Force|Out-Null;Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name MenuShowDelay -Value '100';Log 'Preferences applied; signing out/in may be required'}
 'power' {if(NeedAdmin){Original;Cmd 'powercfg.exe' @('/setactive','SCHEME_MIN')}}
 'undo' {$path=Join-Path $backups 'performance-original.json';if(!(Test-Path $path)){Log 'No baseline found';break};$old=Get-Content $path -Raw|ConvertFrom-Json;$p='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects';if($null -ne $old.visual){New-Item -Path $p -Force|Out-Null;New-ItemProperty -Path $p -Name VisualFXSetting -PropertyType DWord -Value ([int]$old.visual) -Force|Out-Null}else{Remove-ItemProperty -Path $p -Name VisualFXSetting -ErrorAction SilentlyContinue};if($null -ne $old.menu){Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name MenuShowDelay -Value ([string]$old.menu)}else{Remove-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name MenuShowDelay -ErrorAction SilentlyContinue};if($old.power){if(Admin){Cmd 'powercfg.exe' @('/setactive',([string]$old.power))}else{Log 'Elevate to restore power plan'}};Log 'Restore attempted; baseline retained'}
 'restore' {if(NeedAdmin){Checkpoint-Computer -Description 'kim.xz opti works before tweaks' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop;Log 'Restore point created'}}
 'network' {if(NeedAdmin){Log 'WARNING: May disrupt VPN and custom network settings. Restart usually needed.';Cmd 'netsh.exe' @('winsock','reset');Cmd 'netsh.exe' @('int','ip','reset')}}
 'startup' {Start-Process explorer.exe -ArgumentList 'shell:startup'}
 'status' {Log "OS: $([Environment]::OSVersion.VersionString)";Log "Computer: $env:COMPUTERNAME";Cmd 'powercfg.exe' @('/getactivescheme')}
}}catch{Log "ERROR: $($_.Exception.Message)"}
Log "Finished. Session log: $log"
