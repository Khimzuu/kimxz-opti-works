# kim.xz opti works - V1.0
# Local, inspectable Windows 10/11 maintenance utility.
# No downloads, telemetry, security-feature disabling, or hidden changes.
$ErrorActionPreference = 'Continue'
$Host.UI.RawUI.WindowTitle = 'kim.xz opti works | v1.0'
$root = Join-Path $env:LOCALAPPDATA 'kim.xz-opti-works'
$logDir = Join-Path $root 'logs'
$backupDir = Join-Path $root 'backups'
New-Item -ItemType Directory -Force -Path $logDir,$backupDir | Out-Null
$log = Join-Path $logDir ("session-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
function Log([string]$message) { $line = '[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),$message; Write-Host $line; Add-Content -LiteralPath $log -Value $line }
function Admin { $identity = [Security.Principal.WindowsIdentity]::GetCurrent(); $principal = [Security.Principal.WindowsPrincipal]::new($identity); return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) }
function Pause-Menu { Write-Host ''; [void](Read-Host 'Press Enter to return') }
function Confirm([string]$label) { return ((Read-Host "$label [type YES]") -ceq 'YES') }
function Invoke-External([string]$file,[string[]]$arguments) {
    Log ("Running: {0} {1}" -f $file,($arguments -join ' '))
    try { & $file @arguments 2>&1 | ForEach-Object { $s = "$_"; Write-Host $s; Add-Content -LiteralPath $log -Value $s }; Log "Exit code: $LASTEXITCODE" }
    catch { Log "ERROR: $($_.Exception.Message)" }
}
function Need-Admin { if (-not (Admin)) { Log 'Administrator access required for this operation. Relaunch the .bat as administrator.'; return $false }; return $true }
function Clean-Temporary {
    Log 'Cleaning files in user and Windows temporary directories (older than 24 hours).'
    $cutoff = (Get-Date).AddDays(-1)
    $paths = @($env:TEMP, (Join-Path $env:windir 'Temp')) | Select-Object -Unique
    foreach ($path in $paths) {
        if (-not (Test-Path -LiteralPath $path)) { continue }
        if ($path -eq (Join-Path $env:windir 'Temp') -and -not (Admin)) { Log 'Skipping Windows Temp without administrator access.'; continue }
        $count = 0; $failed = 0
        Get-ChildItem -LiteralPath $path -Force -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt $cutoff -and -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) } |
            ForEach-Object { try { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop; $count++ } catch { $failed++ } }
        Log ("{0}: removed {1} files; {2} could not be removed. Active/locked files remain." -f $path,$count,$failed)
    }
}
function Flush-DNS { Invoke-External 'ipconfig.exe' @('/flushdns') }
function Cleanup-Disk {
    Log 'Opening Windows Disk Cleanup (you choose what to remove).'
    if (Get-Command cleanmgr.exe -ErrorAction SilentlyContinue) { Start-Process 'cleanmgr.exe' -Wait }
    else { Log 'Disk Cleanup is unavailable; opening Windows Storage settings.'; Start-Process 'ms-settings:storagesense' }
}
function Restore-Point {
    if (-not (Need-Admin)) { return }
    Log 'Attempting to create a System Restore checkpoint.'
    try { Checkpoint-Computer -Description 'kim.xz opti works - Before tweaks' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop; Log 'Restore point created.' }
    catch { Log "Restore point unavailable: $($_.Exception.Message). Check System Protection settings and the Windows restore-point frequency limit." }
}
function Backup-Registry {
    $path = Join-Path $backupDir ("user-registry-{0}.reg" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
    Invoke-External 'reg.exe' @('export','HKCU', $path, '/y')
    if (Test-Path -LiteralPath $path) { Log "Current-user registry export saved: $path. NOTE: this is not a complete system backup." }
}
function Save-Setting {
    $file = Join-Path $backupDir 'performance-original.json'
    if (Test-Path -LiteralPath $file) { return }
    $visualPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'
    $menuPath = 'HKCU:\Control Panel\Desktop'
    $visual = (Get-ItemProperty -Path $visualPath -Name VisualFXSetting -ErrorAction SilentlyContinue).VisualFXSetting
    $menu = (Get-ItemProperty -Path $menuPath -Name MenuShowDelay -ErrorAction SilentlyContinue).MenuShowDelay
    $powerOutput = powercfg.exe /getactivescheme 2>&1 | Out-String
    $guidMatch = [regex]::Match($powerOutput,'[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}')
    [pscustomobject]@{ VisualFXSetting = $visual; MenuShowDelay = $menu; PowerGUID = $(if($guidMatch.Success){$guidMatch.Value}else{$null}); SavedAt = (Get-Date).ToString('o') } |
        ConvertTo-Json | Set-Content -LiteralPath $file -Encoding UTF8
    Log "Original performance settings saved: $file"
}
function Performance {
    Write-Host 'Changes: set visual-effects preference to best performance, menu delay to 100 ms.'
    Write-Host 'This may affect appearance; power settings are handled separately.'
    if (-not (Confirm 'Apply these per-user preferences?')) { return }
    Save-Setting
    $visualPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'
    if (-not (Test-Path $visualPath)) { New-Item -Path $visualPath -Force | Out-Null }
    New-ItemProperty -Path $visualPath -Name VisualFXSetting -PropertyType DWord -Value 2 -Force | Out-Null
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name MenuShowDelay -Value '100'
    Log 'Per-user preferences updated. Sign out/in may be necessary. Windows may require per-effect configuration for visual changes.'
}
function Set-Power {
    if (-not (Need-Admin)) { return }
    Write-Host 'Switch to built-in High Performance plan (if available). Higher energy use/heat is possible.'
    if (-not (Confirm 'Switch power plan?')) { return }
    Save-Setting
    Invoke-External 'powercfg.exe' @('/setactive','SCHEME_MIN')
}
function Undo-Performance {
    $file = Join-Path $backupDir 'performance-original.json'
    if (-not (Test-Path -LiteralPath $file)) { Log 'No saved settings found; nothing to restore.'; return }
    $old = Get-Content -LiteralPath $file -Raw | ConvertFrom-Json
    if (-not (Confirm 'Restore stored visual, menu and power-plan settings?')) { return }
    $vp = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'
    if ($null -ne $old.VisualFXSetting) { New-ItemProperty -Path $vp -Name VisualFXSetting -PropertyType DWord -Value ([int]$old.VisualFXSetting) -Force | Out-Null }
    else { Remove-ItemProperty -Path $vp -Name VisualFXSetting -ErrorAction SilentlyContinue }
    if ($null -ne $old.MenuShowDelay) { Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name MenuShowDelay -Value ([string]$old.MenuShowDelay) }
    else { Remove-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name MenuShowDelay -ErrorAction SilentlyContinue }
    if ($old.PowerGUID) { if (Admin) { Invoke-External 'powercfg.exe' @('/setactive',([string]$old.PowerGUID)) } else { Log 'Run elevated to restore saved power plan.' } }
    Log 'Restoration attempted. Saved baseline is retained for reference.'
}
function Network-Reset {
    if (-not (Need-Admin)) { return }
    Write-Host 'WARNING: Resets Winsock and TCP/IP settings. VPNs, custom addresses and connectivity may break.'
    Write-Host 'Use only for network troubleshooting. A restart is usually required.'
    if (-not (Confirm 'Reset network stack?')) { return }
    Invoke-External 'netsh.exe' @('winsock','reset')
    Invoke-External 'netsh.exe' @('int','ip','reset')
    Log 'Network reset commands finished. Restart if required.'
}
function Full-Maintenance {
    Write-Host 'Routine maintenance: temp files (older than 24h), DNS flush, optional Disk Cleanup.'
    Write-Host 'Does NOT reset networking, change registry/power settings, or empty Recycle Bin.'
    if (-not (Confirm 'Run routine maintenance?')) { return }
    Clean-Temporary; Flush-DNS
    if (Confirm 'Open interactive Windows Disk Cleanup now?') { Cleanup-Disk }
    Log 'Routine maintenance finished.'
}
function Show-Menu {
    Clear-Host
    Write-Host @'
 _    _                __   __
| | _(_)_ __ ___     \ \ / /_ __
| |/ / | '_ ` _ \     \ V /| '_ \
|   <| | | | | | | _   /   \| |_) |
|_|\_\_|_| |_| |_|(_)_/ /^\ \ .__/
                         \/   |_|
  O P T I   W O R K S
'@ -ForegroundColor White
    Write-Host ('=' * 58)
    Write-Host (' v1.0  |  Windows 10/11  |  Admin: {0}' -f (Admin))
    Write-Host ('=' * 58)
    Write-Host ' [1] Routine Maintenance             [2] Clean Temporary Files'
    Write-Host ' [3] Flush DNS Cache                [4] Empty Recycle Bin'
    Write-Host ' [5] Network Reset (advanced)       [6] Windows Disk Cleanup'
    Write-Host ' [7] SFC System Scan                [8] DISM Image Repair'
    Write-Host ' [9] Backup User Registry           [10] Performance Preferences'
    Write-Host ' [11] Startup Apps Folder           [12] Create Restore Point'
    Write-Host ' [13] High Performance Power Plan   [14] Undo Performance Settings'
    Write-Host ' [15] Show System Status            [0] Exit'
    Write-Host ('-' * 58)
    Write-Host " Logs: $logDir"
    Write-Host ' No security disabling | No hidden installs | No telemetry'
    Write-Host ''
}
Log 'Started kim.xz opti works v1.0.'
while ($true) {
    Show-Menu
    $choice = Read-Host 'Select option'
    Write-Host ''
    switch ($choice) {
        '1' { Full-Maintenance }
        '2' { Clean-Temporary }
        '3' { Flush-DNS }
        '4' { if (Confirm 'Permanently empty your Recycle Bin?') { try { Clear-RecycleBin -Force -ErrorAction Stop; Log 'Recycle Bin emptied.' } catch { Log "Recycle Bin error: $($_.Exception.Message)" } } }
        '5' { Network-Reset }
        '6' { Cleanup-Disk }
        '7' { if (Need-Admin) { Invoke-External 'sfc.exe' @('/scannow') } }
        '8' { if (Need-Admin) { Invoke-External 'dism.exe' @('/Online','/Cleanup-Image','/RestoreHealth') } }
        '9' { Backup-Registry }
        '10' { Performance }
        '11' { Start-Process 'explorer.exe' -ArgumentList 'shell:startup'; Log 'Opened user Startup folder.' }
        '12' { Restore-Point }
        '13' { Set-Power }
        '14' { Undo-Performance }
        '15' { Log "OS: $([Environment]::OSVersion.VersionString)"; Log "Computer: $env:COMPUTERNAME"; Invoke-External 'powercfg.exe' @('/getactivescheme'); Log "Session log: $log" }
        '0' { Log 'Exiting.'; return }
        default { Write-Host 'Invalid option.' }
    }
    Pause-Menu
}
