# kim.xz opti works v2 - Windows PowerShell 5.1 Windows Forms GUI
# No network downloads; actions require explicit user selection.
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
$script:appDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:actionScript = Join-Path $script:appDir 'kimxz-actions.ps1'
$script:dark = [Drawing.Color]::FromArgb(16,18,22)
$script:panel = [Drawing.Color]::FromArgb(25,28,34)
$script:line = [Drawing.Color]::FromArgb(53,58,68)
$script:white = [Drawing.Color]::FromArgb(238,242,247)
$script:muted = [Drawing.Color]::FromArgb(158,167,180)
$script:accent = [Drawing.Color]::FromArgb(94,225,172)
function Is-Administrator {
 $id=[Security.Principal.WindowsIdentity]::GetCurrent()
 $p=New-Object Security.Principal.WindowsPrincipal($id)
 $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
function TextLabel($text,$x,$y,$w,$h,$size=10,$color=$script:white,$bold=$false) {
 $label=New-Object Windows.Forms.Label
 $label.Text=$text; $label.Location=New-Object Drawing.Point($x,$y)
 $label.Size=New-Object Drawing.Size($w,$h)
 $style=if($bold){[Drawing.FontStyle]::Bold}else{[Drawing.FontStyle]::Regular}
 $label.Font=New-Object System.Drawing.Font -ArgumentList 'Segoe UI',$size,$style
 $label.ForeColor=$color; $label.BackColor=[Drawing.Color]::Transparent
 return $label
}
$form=New-Object Windows.Forms.Form
$form.Text='kim.xz opti works | v2.0'
$form.Size=New-Object Drawing.Size(1060,740)
$form.MinimumSize=New-Object Drawing.Size(940,690)
$form.StartPosition='CenterScreen'
$form.BackColor=$script:dark
$form.ForeColor=$script:white
$form.Font=New-Object System.Drawing.Font -ArgumentList 'Segoe UI',10
$form.AutoScaleMode='Dpi'
$form.Icon=[Drawing.SystemIcons]::Application
$header=New-Object Windows.Forms.Panel
$header.BackColor=$script:panel
$header.SetBounds(0,0,1044,120)
$header.Anchor='Top,Left,Right'
$form.Controls.Add($header)
$header.Controls.Add((TextLabel 'kim.xz' 28 14 370 62 34 $script:white $true))
$header.Controls.Add((TextLabel 'OPTI WORKS  /  WINDOWS UTILITY' 30 78 420 22 10 $script:accent $true))
$status=TextLabel ('{0}  |  Windows 10 / 11  |  v2.0' -f $(if(Is-Administrator){'ADMIN MODE'}else{'STANDARD MODE'})) 675 33 340 30 10 $script:muted $true
$status.Anchor='Top,Right';$header.Controls.Add($status)
$intro=TextLabel 'MAINTENANCE & DIAGNOSTICS' 28 145 650 32 16 $script:white $true
$form.Controls.Add($intro)
$form.Controls.Add((TextLabel 'Choose one action. Critical changes ask for confirmation; no automatic “boost” tweaks.' 29 181 925 28 10 $script:muted))
$items=@(
 @('Routine maintenance','Remove older temp files and flush DNS','maintenance',$false,$false),
 @('Clean temporary files','Remove temp files older than 24 hours','temp',$false,$false),
 @('Flush DNS','Clear resolver cache','dns',$false,$false),
 @('Empty Recycle Bin','Permanently delete recycled files','recycle',$false,$true),
 @('Windows Disk Cleanup','Open the built-in cleanup interface','cleanup',$false,$false),
 @('SFC system scan','Verify and repair system files','sfc',$true,$false),
 @('DISM repair','Repair the Windows component store','dism',$true,$false),
 @('Backup user registry','Export HKCU (not a full backup)','registry',$false,$false),
 @('Performance preferences','Visual effects and menu delay','performance',$false,$true),
 @('High performance power','May increase heat and power use','power',$true,$true),
 @('Undo performance settings','Restore saved preference baseline','undo',$false,$true),
 @('Create restore point','Requires enabled System Protection','restore',$true,$false),
 @('Network reset','Can disconnect VPN and custom networking','network',$true,$true),
 @('Startup apps folder','Open the current user startup folder','startup',$false,$false),
 @('System status','Show OS and current power plan','status',$false,$false)
)
$scroll=New-Object Windows.Forms.FlowLayoutPanel
$scroll.SetBounds(28,224,980,375)
$scroll.Anchor='Top,Left,Right,Bottom'
$scroll.AutoScroll=$true
$scroll.WrapContents=$true
$scroll.FlowDirection='LeftToRight'
$form.Controls.Add($scroll)
$script:message=TextLabel 'Ready. All changes are initiated manually.' 29 617 960 26 10 $script:muted
$script:message.Anchor='Bottom,Left,Right';$form.Controls.Add($script:message)
$footer=TextLabel 'LOCAL-FIRST  /  NO TELEMETRY  /  LOGS IN LOCALAPPDATA  /  REVIEW CODE BEFORE DISTRIBUTING' 29 662 945 24 9 $script:muted
$footer.Anchor='Bottom,Left,Right';$form.Controls.Add($footer)
function Launch-Action([string]$action,[string]$label,[bool]$admin,[bool]$caution) {
 if(!(Test-Path -LiteralPath $script:actionScript)){
  [Windows.Forms.MessageBox]::Show('Missing kimxz-actions.ps1 beside this GUI file.','Missing file','OK','Error')|Out-Null;return
 }
 if($caution){
  $response=[Windows.Forms.MessageBox]::Show("Run '$label'?`r`n`r`nRead the action description. Some changes are irreversible or require a restart.",'Confirm action','YesNo','Warning')
  if($response -ne [Windows.Forms.DialogResult]::Yes){return}
 }
 if($admin -and !(Is-Administrator)) {
  $response=[Windows.Forms.MessageBox]::Show("'$label' requires administrator rights. Windows will ask for permission to elevate the action only.",'Administrator permission','YesNo','Question')
  if($response -ne [Windows.Forms.DialogResult]::Yes){return}
 }
 $params=@('-NoProfile','-NoExit','-File',('"'+$script:actionScript+'"'),'-Action',$action)
 try {
  $start=@{FilePath='powershell.exe';ArgumentList=($params -join ' ');WorkingDirectory=$script:appDir;ErrorAction='Stop'}
  if($admin -and !(Is-Administrator)){$start.Verb='RunAs'}
  Start-Process @start
  $script:message.Text="Launched: $label (results appear in a separate PowerShell window)."
 }catch{[Windows.Forms.MessageBox]::Show($_.Exception.Message,'Action could not start','OK','Error')|Out-Null}
}
foreach($item in $items){
 $name=[string]$item[0];$desc=[string]$item[1];$action=[string]$item[2];$requiresAdmin=[bool]$item[3];$danger=[bool]$item[4]
 $tile=New-Object Windows.Forms.Panel
 $tile.Width=460;$tile.Height=86;$tile.Margin=New-Object Windows.Forms.Padding(0,0,13,11)
 $tile.BackColor=$script:panel
 $button=New-Object Windows.Forms.Button
 $button.Text=$name.ToUpperInvariant() + $(if($requiresAdmin){'  [ADMIN]'}else{''})
 $button.FlatStyle='Flat';$button.FlatAppearance.BorderSize=1;$button.FlatAppearance.BorderColor=$script:line
 $button.ForeColor=$script:white;$button.BackColor=$script:panel
 $button.Font=New-Object System.Drawing.Font -ArgumentList 'Segoe UI',10,([Drawing.FontStyle]::Bold)
 $button.TextAlign='MiddleLeft';$button.SetBounds(12,9,433,37)
 $button.Tag=@{action=$action;label=$name;admin=$requiresAdmin;caution=$danger}
 $button.Add_Click({$t=$this.Tag;Launch-Action $t.action $t.label $t.admin $t.caution})
 $tile.Controls.Add($button)
 $tile.Controls.Add((TextLabel $desc 16 54 424 24 9 $script:muted))
 $scroll.Controls.Add($tile)
}
[void]$form.ShowDialog()
