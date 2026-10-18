# kim.xz opti works V3 — Windows PowerShell 5.1 / Windows Forms
# GUI never changes system state until a user clicks a button.
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()
$script:dir=Split-Path -Parent $MyInvocation.MyCommand.Path
$script:worker=Join-Path $script:dir 'kimxz-worker.ps1'
$script:bg=[Drawing.Color]::FromArgb(8,13,20)
$script:panel=[Drawing.Color]::FromArgb(19,27,37)
$script:card=[Drawing.Color]::FromArgb(26,37,48)
$script:accent=[Drawing.Color]::FromArgb(80,224,191)
$script:fg=[Drawing.Color]::FromArgb(238,242,247)
$script:muted=[Drawing.Color]::FromArgb(155,174,190)
$script:jobProcess=$null;$script:statusPath=$null;$script:page='home'
function Font($size=10,$bold=$false){[Drawing.Font]::new('Segoe UI',$size,$(if($bold){[Drawing.FontStyle]::Bold}else{[Drawing.FontStyle]::Regular}))}
function Label($text,$x,$y,$w,$h,$size=10,$color=$script:fg,$bold=$false){
 $l=New-Object Windows.Forms.Label;$l.Text=$text;$l.SetBounds($x,$y,$w,$h);$l.Font=Font $size $bold;$l.ForeColor=$color;$l.BackColor=[Drawing.Color]::Transparent;return $l
}
function Button($text,$x,$y,$w,$h,$action,$primary=$false){
 $b=New-Object Windows.Forms.Button;$b.Text=$text;$b.SetBounds($x,$y,$w,$h);$b.FlatStyle='Flat';$b.FlatAppearance.BorderSize=1
 $b.FlatAppearance.BorderColor=$(if($primary){$script:accent}else{[Drawing.Color]::FromArgb(57,75,91)})
 $b.BackColor=$(if($primary){$script:accent}else{$script:card});$b.ForeColor=$(if($primary){$script:bg}else{$script:fg});$b.Font=Font 10 $true
 $b.Add_Click($action);return $b
}
$form=New-Object Windows.Forms.Form
$form.Text='kim.xz opti works | V3.0';$form.ClientSize=New-Object Drawing.Size(1200,780)
$form.MinimumSize=New-Object Drawing.Size(990,690);$form.StartPosition='CenterScreen';$form.BackColor=$script:bg;$form.ForeColor=$script:fg
$sidebar=New-Object Windows.Forms.Panel;$sidebar.SetBounds(0,0,218,780);$sidebar.BackColor=$script:panel;$sidebar.Anchor='Top,Bottom,Left';$form.Controls.Add($sidebar)
$sidebar.Controls.Add((Label 'kim.xz' 22 25 180 56 29 $script:fg $true))
$sidebar.Controls.Add((Label 'O P T I   W O R K S' 25 83 185 26 9 $script:accent $true))
$main=New-Object Windows.Forms.Panel;$main.SetBounds(218,0,982,646);$main.Anchor='Top,Bottom,Left,Right';$main.AutoScroll=$true;$main.BackColor=$script:bg;$form.Controls.Add($main)
$footer=New-Object Windows.Forms.Panel;$footer.SetBounds(218,646,982,134);$footer.Anchor='Bottom,Left,Right';$footer.BackColor=$script:panel;$form.Controls.Add($footer)
$stateLabel=Label 'READY  |  Select a preset or open Manual tools.' 24 10 900 25 11 $script:accent $true
$stateLabel.Anchor='Top,Left,Right';$footer.Controls.Add($stateLabel)
$progress=New-Object Windows.Forms.ProgressBar;$progress.SetBounds(24,40,925,16);$progress.Anchor='Top,Left,Right';$progress.Style='Continuous';$footer.Controls.Add($progress)
$logLabel=Label 'No task running.' 24 66 925 35 9 $script:muted
$logLabel.Anchor='Top,Left,Right';$footer.Controls.Add($logLabel)
function AddNav($name,$y,$route){
 $b=Button $name 13 $y 190 48 ({Show-Page ([string]$this.Tag)});$b.Tag=$route;$sidebar.Controls.Add($b)
}
function IsAdmin{ $p=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent());$p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)}
function Start-Job($task,$warning=''){
 if($script:jobProcess -and -not $script:jobProcess.HasExited){[Windows.Forms.MessageBox]::Show('An optimization is already running. Wait for it to finish.','Busy')|Out-Null;return}
 if(!(Test-Path -LiteralPath $script:worker)){[Windows.Forms.MessageBox]::Show('Missing kimxz-worker.ps1 beside the GUI.','Missing file')|Out-Null;return}
 if($warning){$response=[Windows.Forms.MessageBox]::Show(($warning+"`r`n`r`nContinue?"),'Confirm advanced operation','YesNo','Warning');if($response -ne 'Yes'){return}}
 $adminJobs=@('sfc','dism','restorepoint','network','driveopt')
 if(($adminJobs -contains $task) -and !(IsAdmin)){
  [Windows.Forms.MessageBox]::Show('This action requires elevation. Relaunch the application as Administrator for this tool.','Administrator rights required')|Out-Null;return
 }
 $session=Join-Path $env:LOCALAPPDATA 'kim.xz-opti-works\status';New-Item -ItemType Directory -Force -Path $session|Out-Null
 $script:statusPath=Join-Path $session ('job-'+[guid]::NewGuid().ToString('N')+'.json')
 $psi=New-Object System.Diagnostics.ProcessStartInfo
 $psi.FileName=(Join-Path $PSHOME 'powershell.exe');$psi.Arguments='-NoProfile -NonInteractive -File "'+$script:worker+'" -Job "'+$task+'" -StatusPath "'+$script:statusPath+'"'
 $psi.UseShellExecute=$false;$psi.CreateNoWindow=$true;$psi.WindowStyle=[Diagnostics.ProcessWindowStyle]::Hidden
 try {$script:jobProcess=[Diagnostics.Process]::Start($psi);$progress.Value=0;$stateLabel.Text="RUNNING  |  $task";$logLabel.Text='Worker started';$timer.Start()}catch{[Windows.Forms.MessageBox]::Show($_.Exception.Message,'Launch error')|Out-Null}
}
$timer=New-Object Windows.Forms.Timer;$timer.Interval=450
$timer.Add_Tick({
 if($script:statusPath -and (Test-Path -LiteralPath $script:statusPath)){
  try {
   $j=Get-Content -LiteralPath $script:statusPath -Raw | ConvertFrom-Json
   $logLabel.Text=[string]$j.message
   if($j.total -gt 0){$progress.Value=[int][Math]::Min(100,[Math]::Max(0,100*$j.done/$j.total))}
   if($j.state -in @('success','partial','failed')){$stateLabel.Text=($j.state.ToUpper()+'  |  '+$j.message);$timer.Stop()}
  }catch{}
 }
 if($script:jobProcess -and $script:jobProcess.HasExited -and $timer.Enabled){$timer.Stop();$stateLabel.Text='FINISHED  |  Open logs for details'}
})
function ClearMain{$main.Controls.Clear();$main.AutoScrollPosition=New-Object Drawing.Point(0,0)}
function Show-Page($route){
 $script:page=$route;ClearMain
 $main.Controls.Add((Label 'kim.xz  /  OPTI WORKS' 32 25 900 35 19 $script:fg $true))
 $main.Controls.Add((Label 'WINDOWS 10/11  •  V3.0  •  LOW-END PC PERFORMANCE UTILITY' 34 70 900 22 9 $script:accent))
 if($route -eq 'home'){
  $main.Controls.Add((Label 'CHOOSE YOUR MODE' 32 124 850 48 24 $script:fg $true))
  $main.Controls.Add((Label 'One click starts an invisible worker. Track its progress in the bottom bar.' 33 178 880 32 11 $script:muted))
  $main.Controls.Add((Label '01  /  STANDARD OPTIMIZE' 40 245 865 36 17 $script:fg $true))
  $main.Controls.Add((Label 'Recommended: system status, disk-space report, older temp-file cleanup, DNS flush. No security changes.' 40 283 850 55 10 $script:muted))
  $main.Controls.Add((Button 'RUN STANDARD OPTIMIZE  >' 40 349 840 49 ({Start-Job 'standard'}) $true))
  $main.Controls.Add((Label '02  /  ADVANCED OPTIMIZE' 40 434 865 36 17 $script:fg $true))
  $main.Controls.Add((Label 'Standard + visual preferences + Game Mode + Windows drive optimization + Defender status check. No destructive reset.' 40 472 850 55 10 $script:muted))
  $main.Controls.Add((Button 'RUN ADVANCED OPTIMIZE  >' 40 543 840 49 ({Start-Job 'advanced' 'Advanced Optimize changes user visual preferences and Game Mode. Drive optimization may take time. A baseline is saved for visual preferences; not every action can be undone.'}) $true))
  $main.Controls.Add((Button '03  /  MANUAL  —  CHOOSE INDIVIDUAL TOOLS  >' 40 619 840 49 ({Show-Page 'manual'})))
 }else{
  $main.Controls.Add((Label 'MANUAL OPTIMIZATION DASHBOARD' 32 117 870 40 20 $script:fg $true))
  $main.Controls.Add((Label 'Click a tool once to launch. Some system actions require Administrator privileges.' 33 160 890 30 10 $script:muted))
  $items=@(
   @('Clean temporary files','temp','CLEANUP','Removes files older than 48 hours where safe',''),
   @('Flush DNS cache','dns','NETWORK','Clears cached DNS resolver entries',''),
   @('Disk space report','diskreport','DIAGNOSTICS','Displays available C: disk space',''),
   @('System information','status','DIAGNOSTICS','Windows version and installed RAM',''),
   @('Performance visuals','visual','PERFORMANCE','Prefers reduced effects; creates backup','Changing appearance may require sign-out.'),
   @('Enable Game Mode','gamemode','GAMING','Enable Windows Game Mode user setting',''),
   @('High Performance power','power','GAMING','Higher energy use and heat possible','May increase heat, power use, and fan noise.'),
   @('Optimize C: drive','driveopt','STORAGE','Lets Windows choose SSD trim or HDD optimization','Drive optimization may take a while.'),
   @('SFC scan','sfc','SYSTEM REPAIR','Verifies protected Windows files',''),
   @('DISM repair','dism','SYSTEM REPAIR','Repairs Windows component store',''),
   @('Export user registry','registry','BACKUP','Exports HKCU only, not whole-system backup',''),
   @('Create restore point','restorepoint','RECOVERY','Requests Windows system restore point',''),
   @('Undo visual preferences','revert','RECOVERY','Restore stored visuals and menu delay',''),
   @('Defender status','defenderstatus','SECURITY','Reports real-time and tamper protection',''),
   @('Empty Recycle Bin','recycle','DESTRUCTIVE','Permanently deletes recycled files','All Recycle Bin items will be permanently deleted.'),
   @('Reset network stack','network','NETWORK','May break VPN and custom configuration','Resets Winsock and TCP/IP. Connectivity and VPNs may be disrupted; reboot may be needed.')
  )
  $y=207
  foreach($i in $items){
   $name=$i[0];$task=$i[1];$category=$i[2];$description=$i[3];$warning=$i[4]
   $box=New-Object Windows.Forms.Panel;$box.SetBounds(30,$y,850,73);$box.BackColor=$script:panel
   $box.Controls.Add((Label $name 13 7 590 27 12 $script:fg $true))
   $box.Controls.Add((Label "$category  /  $description" 13 40 605 25 9 $script:muted))
   $button=Button 'RUN  >' 695 15 135 42 ({$b=$this.Tag;Start-Job $b.task $b.warning}) $false
   $button.Tag=@{task=$task;warning=$warning};$box.Controls.Add($button)
   $main.Controls.Add($box);$y+=83
  }
  $main.Controls.Add((Button 'OPEN STARTUP SETTINGS' 30 ($y+10) 265 42 ({Start-Process 'ms-settings:startupapps'})))
  $main.Controls.Add((Button 'GAME GRAPHICS SETTINGS' 305 ($y+10) 265 42 ({Start-Process 'ms-settings:display-advancedgraphics'})))
  $main.Controls.Add((Button 'DEFENDER CONTROLS' 580 ($y+10) 300 42 ({try{Start-Process 'windowsdefender://threatsettings'}catch{Start-Process 'ms-settings:windowsdefender'}})))
  $main.Controls.Add((Label 'Defender protection changes remain in Windows Security; this tool does not disable antivirus or Windows Update.' 32 ($y+62) 845 46 9 $script:muted))
 }
}
AddNav 'Dashboard / Modes' 155 'home'
AddNav 'Manual Tool Selection' 216 'manual'
$sidebar.Controls.Add((Label 'SAFE BY DEFAULT' 20 683 190 24 9 $script:accent $true))
$sidebar.Controls.Add((Label 'NO HIDDEN TWEAKS' 20 708 180 24 9 $script:muted))
$sidebar.Controls.Add((Label 'V3.0 / LOCAL LOGS' 20 732 180 24 9 $script:muted))
Show-Page 'home'
[void]$form.ShowDialog()
