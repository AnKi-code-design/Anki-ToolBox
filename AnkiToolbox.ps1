# Anki Toolbox — CTT WinUtil-inspired Windows settings UI
# Launch: irm https://raw.githubusercontent.com/AnKi-code-design/Anki-ToolBox/fix-toolbox-parse-error/AnkiToolbox.ps1 | iex

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
if ($env:OS -ne 'Windows_NT') { throw 'Anki Toolbox requires Windows.' }

# A piped script has no $PSCommandPath. Re-fetch this bootstrap when elevation is needed.
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $url = 'https://raw.githubusercontent.com/AnKi-code-design/Anki-ToolBox/fix-toolbox-parse-error/AnkiToolbox.ps1'
    Start-Process powershell.exe -Verb RunAs -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', "irm '$url' | iex")
    return
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

function Set-ToolboxRegistryValue {
    param([string]$Path, [string]$Name, $Value, [string]$Kind = 'DWord')
    if (-not (Test-Path -LiteralPath $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -PropertyType $Kind -Force | Out-Null
}

$script:ToolboxTweaks = @(
    @{ Id=1; Category='Appearance'; Name='Dark Mode'; Description='Use dark colors for Windows and apps'; Safe=$true; Action={ Set-ToolboxRegistryValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'AppsUseLightTheme' 0; Set-ToolboxRegistryValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'SystemUsesLightTheme' 0 } },
    @{ Id=2; Category='Appearance'; Name='Transparency Effects'; Description='Turn off Windows transparency'; Safe=$true; Action={ Set-ToolboxRegistryValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 0 } },
    @{ Id=3; Category='Explorer'; Name='Show File Extensions'; Description='Display .txt, .jpg and other file extensions'; Safe=$true; Action={ Set-ToolboxRegistryValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'HideFileExt' 0 } },
    @{ Id=4; Category='Explorer'; Name='Hide Recent Files'; Description='Stop showing recent files in Explorer'; Safe=$true; Action={ Set-ToolboxRegistryValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer' 'ShowRecent' 0 } },
    @{ Id=5; Category='Gaming'; Name='Enable Game Mode'; Description='Enable Windows Game Mode for this user'; Safe=$true; Action={ Set-ToolboxRegistryValue 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1 } },
    @{ Id=6; Category='Gaming'; Name='Disable Game DVR'; Description='Disable background Game DVR capture'; Safe=$false; Action={ Set-ToolboxRegistryValue 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0 } },
    @{ Id=7; Category='Privacy'; Name='Disable Advertising ID'; Description='Turn off Windows advertising ID for this user'; Safe=$true; Action={ Set-ToolboxRegistryValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0 } },
    @{ Id=8; Category='Performance'; Name='Visual Effects: Performance'; Description='Prefer performance over visual effects'; Safe=$false; Action={ Set-ToolboxRegistryValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 2 } }
)
$script:SelectedIds = @{}
$script:CurrentCategory = 'All'
$script:ActiveTab = 'Tweaks'
$script:CardButtons = @{}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Anki Toolbox"
$form.StartPosition = 'CenterScreen'
$form.Size = New-Object System.Drawing.Size(1140, 770)
$form.MinimumSize = New-Object System.Drawing.Size(960, 650)
$form.BackColor = [System.Drawing.Color]::FromArgb(34, 43, 61)
$form.ForeColor = [System.Drawing.Color]::FromArgb(232, 237, 247)
$form.Font = New-Object System.Drawing.Font('Segoe UI', 9)

$header = New-Object System.Windows.Forms.Panel
$header.Dock = 'Top'
$header.Height = 52
$header.BackColor = [System.Drawing.Color]::FromArgb(35, 45, 64)
$form.Controls.Add($header)

$brand = New-Object System.Windows.Forms.Label
$brand.Text = '⚡'
$brand.Font = New-Object System.Drawing.Font('Segoe UI Symbol', 20, [System.Drawing.FontStyle]::Bold)
$brand.ForeColor = [System.Drawing.Color]::FromArgb(75, 151, 255)
$brand.Location = New-Object System.Drawing.Point(12, 4)
$brand.Size = New-Object System.Drawing.Size(42, 42)
$header.Controls.Add($brand)

$script:NavButtons = @{}
$navNames = @('Install', 'Tweaks', 'Config', 'Updates', 'Win11 Creator')
$navX = 58
foreach ($navName in $navNames) {
    $nav = New-Object System.Windows.Forms.Button
    $nav.Text = $navName
    $nav.Tag = $navName
    $nav.Location = New-Object System.Drawing.Point($navX, 9)
    $nav.Size = New-Object System.Drawing.Size($(if ($navName -eq 'Win11 Creator') { 122 } else { 105 }), 34)
    $nav.FlatStyle = 'Flat'
    $nav.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(102, 119, 147)
    $nav.ForeColor = [System.Drawing.Color]::White
    $nav.BackColor = [System.Drawing.Color]::FromArgb(39, 50, 70)
    $nav.Add_Click({
        $script:ActiveTab = [string]$this.Tag
        foreach ($b in $script:NavButtons.Values) { $b.BackColor = [System.Drawing.Color]::FromArgb(39, 50, 70) }
        $this.BackColor = [System.Drawing.Color]::FromArgb(58, 101, 165)
        Update-ToolboxView
    })
    $header.Controls.Add($nav)
    $script:NavButtons[$navName] = $nav
    $navX += $nav.Width + 5
}
$script:NavButtons['Tweaks'].BackColor = [System.Drawing.Color]::FromArgb(58, 101, 165)

$script:SearchBox = New-Object System.Windows.Forms.TextBox
$script:SearchBox.Location = New-Object System.Drawing.Point(650, 11)
$script:SearchBox.Size = New-Object System.Drawing.Size(225, 28)
$script:SearchBox.Anchor = 'Top, Right'
$script:SearchBox.BackColor = [System.Drawing.Color]::FromArgb(23, 31, 45)
$script:SearchBox.ForeColor = [System.Drawing.Color]::White
$script:SearchBox.Add_TextChanged({ Update-ToolboxView })
$header.Controls.Add($script:SearchBox)

$script:SafeMode = New-Object System.Windows.Forms.CheckBox
$script:SafeMode.Text = 'Safe'
$script:SafeMode.Location = New-Object System.Drawing.Point(890, 15)
$script:SafeMode.Size = New-Object System.Drawing.Size(62, 24)
$script:SafeMode.Anchor = 'Top, Right'
$script:SafeMode.Checked = $true
$script:SafeMode.Add_CheckedChanged({ Update-ToolboxView })
$header.Controls.Add($script:SafeMode)

$side = New-Object System.Windows.Forms.Panel
$side.Location = New-Object System.Drawing.Point(0, 52)
$side.Size = New-Object System.Drawing.Size(215, 675)
$side.Anchor = 'Top, Bottom, Left'
$side.BackColor = [System.Drawing.Color]::FromArgb(30, 39, 56)
$side.BorderStyle = 'FixedSingle'
$form.Controls.Add($side)

function Add-SideHeading([string]$Text, [int]$Y) {
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $Text
    $l.Location = New-Object System.Drawing.Point(10, $Y)
    $l.Size = New-Object System.Drawing.Size(190, 25)
    $l.Font = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
    $l.ForeColor = [System.Drawing.Color]::FromArgb(123, 177, 255)
    $side.Controls.Add($l)
}
function Add-SideButton([string]$Text, [int]$Y, [scriptblock]$Action) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $Text
    $b.Location = New-Object System.Drawing.Point(8, $Y)
    $b.Size = New-Object System.Drawing.Size(190, 32)
    $b.FlatStyle = 'Flat'
    $b.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(92, 104, 124)
    $b.BackColor = [System.Drawing.Color]::FromArgb(43, 53, 70)
    $b.ForeColor = [System.Drawing.Color]::White
    $b.Add_Click($Action)
    $side.Controls.Add($b)
}
Add-SideHeading 'Actions' 12
Add-SideButton 'Apply Selected Tweaks' 42 { Invoke-ApplySelected }
Add-SideButton 'Select All Shown' 78 { foreach ($item in $script:VisibleTweaks) { $script:SelectedIds[[string]$item.Id] = $true }; Update-ToolboxView }
Add-SideButton 'Clear Selection' 114 { $script:SelectedIds = @{}; Update-ToolboxView }
Add-SideHeading 'Categories' 165
Add-SideButton 'All Tweaks' 196 { $script:CurrentCategory = 'All'; Update-ToolboxView }
Add-SideButton 'Appearance' 232 { $script:CurrentCategory = 'Appearance'; Update-ToolboxView }
Add-SideButton 'Explorer' 268 { $script:CurrentCategory = 'Explorer'; Update-ToolboxView }
Add-SideButton 'Gaming' 304 { $script:CurrentCategory = 'Gaming'; Update-ToolboxView }
Add-SideButton 'Privacy' 340 { $script:CurrentCategory = 'Privacy'; Update-ToolboxView }
Add-SideButton 'Performance' 376 { $script:CurrentCategory = 'Performance'; Update-ToolboxView }
$sideNote = New-Object System.Windows.Forms.Label
$sideNote.Text = 'Safe mode hides settings marked for review. Changes are not made until you click Apply.'
$sideNote.Location = New-Object System.Drawing.Point(10, 435)
$sideNote.Size = New-Object System.Drawing.Size(188, 90)
$sideNote.ForeColor = [System.Drawing.Color]::FromArgb(175, 188, 208)
$side.Controls.Add($sideNote)

$script:MainPanel = New-Object System.Windows.Forms.Panel
$script:MainPanel.Location = New-Object System.Drawing.Point(222, 58)
$script:MainPanel.Size = New-Object System.Drawing.Size(900, 660)
$script:MainPanel.Anchor = 'Top, Bottom, Left, Right'
$script:MainPanel.BackColor = [System.Drawing.Color]::FromArgb(31, 40, 57)
$script:MainPanel.BorderStyle = 'FixedSingle'
$form.Controls.Add($script:MainPanel)

$script:CategoryBar = New-Object System.Windows.Forms.FlowLayoutPanel
$script:CategoryBar.Location = New-Object System.Drawing.Point(12, 10)
$script:CategoryBar.Size = New-Object System.Drawing.Size(860, 42)
$script:CategoryBar.Anchor = 'Top, Left, Right'
$script:CategoryBar.WrapContents = $false
$script:CategoryBar.AutoScroll = $true
$script:MainPanel.Controls.Add($script:CategoryBar)

$script:CardsPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$script:CardsPanel.Location = New-Object System.Drawing.Point(12, 62)
$script:CardsPanel.Size = New-Object System.Drawing.Size(860, 570)
$script:CardsPanel.Anchor = 'Top, Bottom, Left, Right'
$script:CardsPanel.AutoScroll = $true
$script:CardsPanel.WrapContents = $true
$script:CardsPanel.BackColor = [System.Drawing.Color]::FromArgb(31, 40, 57)
$script:MainPanel.Controls.Add($script:CardsPanel)

$script:VisibleTweaks = @()
function Update-ToolboxView {
    if ($null -eq $script:CardsPanel) { return }
    $script:CategoryBar.Controls.Clear()
    $script:CardsPanel.Controls.Clear()
    if ($script:ActiveTab -ne 'Tweaks') {
        $message = New-Object System.Windows.Forms.Label
        $message.Text = "$($script:ActiveTab) is not part of this settings-only toolbox yet.`r`nChoose Tweaks to browse the available Windows settings."
        $message.Location = New-Object System.Drawing.Point(30, 35)
        $message.Size = New-Object System.Drawing.Size(700, 80)
        $message.Font = New-Object System.Drawing.Font('Segoe UI', 14)
        $message.ForeColor = [System.Drawing.Color]::FromArgb(205, 215, 230)
        $script:CardsPanel.Controls.Add($message)
        return
    }

    $categories = @('All') + @($script:ToolboxTweaks.Category | Sort-Object -Unique)
    foreach ($cat in $categories) {
        $chip = New-Object System.Windows.Forms.Button
        $chip.Text = $cat
        $chip.Tag = $cat
        $chip.AutoSize = $true
        $chip.Height = 30
        $chip.FlatStyle = 'Flat'
        $chip.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(80, 101, 132)
        $chip.BackColor = if ($script:CurrentCategory -eq $cat) { [System.Drawing.Color]::FromArgb(60, 104, 168) } else { [System.Drawing.Color]::FromArgb(39, 50, 70) }
        $chip.ForeColor = [System.Drawing.Color]::White
        $chip.Add_Click({ $script:CurrentCategory = [string]$this.Tag; Update-ToolboxView })
        $script:CategoryBar.Controls.Add($chip)
    }

    $query = $script:SearchBox.Text.Trim()
    $script:VisibleTweaks = @($script:ToolboxTweaks | Where-Object {
        ($script:CurrentCategory -eq 'All' -or $_.Category -eq $script:CurrentCategory) -and
        (-not $script:SafeMode.Checked -or $_.Safe) -and
        ([string]::IsNullOrWhiteSpace($query) -or $_.Name.IndexOf($query, [StringComparison]::OrdinalIgnoreCase) -ge 0 -or $_.Description.IndexOf($query, [StringComparison]::OrdinalIgnoreCase) -ge 0)
    })
    $script:CardButtons = @{}
    foreach ($item in $script:VisibleTweaks) {
        $card = New-Object System.Windows.Forms.Button
        $card.Text = "$(if ($script:SelectedIds.ContainsKey([string]$item.Id)) { '✓  ' } else { '    ' })$($item.Name)`r`n$($item.Description)"
        $card.TextAlign = 'MiddleLeft'
        $card.Size = New-Object System.Drawing.Size(270, 70)
        $card.Margin = New-Object System.Windows.Forms.Padding(4)
        $card.FlatStyle = 'Flat'
        $card.FlatAppearance.BorderColor = if ($script:SelectedIds.ContainsKey([string]$item.Id)) { [System.Drawing.Color]::FromArgb(63, 180, 130) } else { [System.Drawing.Color]::FromArgb(115, 127, 145) }
        $card.FlatAppearance.BorderSize = 1
        $card.BackColor = if ($script:SelectedIds.ContainsKey([string]$item.Id)) { [System.Drawing.Color]::FromArgb(44, 75, 77) } else { [System.Drawing.Color]::FromArgb(38, 48, 65) }
        $card.ForeColor = [System.Drawing.Color]::White
        $card.Tag = $item.Id
        $card.Add_Click({
            $key = [string]$this.Tag
            if ($script:SelectedIds.ContainsKey($key)) { $script:SelectedIds.Remove($key) } else { $script:SelectedIds[$key] = $true }
            Update-ToolboxView
        })
        $script:CardsPanel.Controls.Add($card)
        $script:CardButtons[[string]$item.Id] = $card
    }
    $form.Text = "Anki Toolbox — $($script:VisibleTweaks.Count) settings shown / $($script:SelectedIds.Count) selected"
}

function Invoke-ApplySelected {
    $selected = @($script:ToolboxTweaks | Where-Object { $script:SelectedIds.ContainsKey([string]$_.Id) })
    if ($selected.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show('Select one or more settings first.', 'Anki Toolbox', 'OK', 'Information') | Out-Null
        return
    }
    $names = ($selected | ForEach-Object { "• $($_.Name)" }) -join [Environment]::NewLine
    $result = [System.Windows.Forms.MessageBox]::Show("Apply these $($selected.Count) settings?`r`n`r`n$names`r`n`r`nReview the selection carefully. Windows settings will be changed.", 'Confirm changes', 'YesNo', 'Warning')
    if ($result -ne [System.Windows.Forms.DialogResult]::Yes) { return }
    $done = 0
    $failed = @()
    foreach ($item in $selected) {
        try { & $item.Action; $done++ } catch { $failed += $item.Name }
    }
    if ($failed.Count -gt 0) {
        [System.Windows.Forms.MessageBox]::Show("Applied $done setting(s). Failed: $($failed -join ', ')", 'Completed with errors', 'OK', 'Warning') | Out-Null
    } else {
        [System.Windows.Forms.MessageBox]::Show("Applied $done setting(s). Some changes may need signing out or restarting Windows.", 'Done', 'OK', 'Information') | Out-Null
    }
}

Update-ToolboxView
[void]$form.ShowDialog()
