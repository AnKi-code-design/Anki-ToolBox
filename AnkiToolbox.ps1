# Anki Toolbox - Windows PowerShell 5.1+
# Bootstrap: irm https://raw.githubusercontent.com/AnKi-code-design/Anki-ToolBox/fix-toolbox-parse-error/AnkiToolbox.ps1 | iex

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

if ($env:OS -ne 'Windows_NT') {
    throw 'Anki Toolbox requires Windows PowerShell on Windows.'
}

# Piped launchers do not populate $PSCommandPath, so elevate by re-running this bootstrap URL.
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $bootstrapUrl = 'https://raw.githubusercontent.com/AnKi-code-design/Anki-ToolBox/fix-toolbox-parse-error/AnkiToolbox.ps1'
    $elevatedCommand = "irm '$bootstrapUrl' | iex"
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', $elevatedCommand)
    return
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

function Set-ToolboxRegistryValue {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)]$Value,
        [ValidateSet('DWord', 'String')][string]$Kind = 'DWord'
    )
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    New-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -PropertyType $Kind -Force | Out-Null
}

$script:ToolboxTweaks = @(
    @{ Id = 1; Category = 'Appearance'; Name = 'Use dark mode'; Description = 'Set the Windows apps and system theme to dark.'; Safe = $true; Presets = @('Essentials'); Action = { Set-ToolboxRegistryValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'AppsUseLightTheme' 0; Set-ToolboxRegistryValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'SystemUsesLightTheme' 0 } },
    @{ Id = 2; Category = 'Appearance'; Name = 'Turn off transparency'; Description = 'Disable Windows transparency effects.'; Safe = $true; Presets = @('Essentials'); Action = { Set-ToolboxRegistryValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 0 } },
    @{ Id = 3; Category = 'Explorer'; Name = 'Show file extensions'; Description = 'Show extensions such as .txt and .jpg in File Explorer.'; Safe = $true; Presets = @('Essentials'); Action = { Set-ToolboxRegistryValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'HideFileExt' 0 } },
    @{ Id = 4; Category = 'Explorer'; Name = 'Hide recent items'; Description = 'Turn off recent-file history in File Explorer.'; Safe = $true; Presets = @('Essentials'); Action = { Set-ToolboxRegistryValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer' 'ShowRecent' 0 } },
    @{ Id = 5; Category = 'Gaming'; Name = 'Enable Game Mode'; Description = 'Enable Windows Game Mode; restart your game for it to take effect.'; Safe = $true; Presets = @('Gaming'); Action = { Set-ToolboxRegistryValue 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1 } },
    @{ Id = 6; Category = 'Gaming'; Name = 'Turn off Game DVR capture'; Description = 'Disable background Xbox Game DVR recording. Xbox capture features may be affected.'; Safe = $false; Presets = @('Gaming'); Action = { Set-ToolboxRegistryValue 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0 } },
    @{ Id = 7; Category = 'Privacy'; Name = 'Disable advertising ID'; Description = 'Disable the Windows advertising ID for this user.'; Safe = $true; Presets = @('Essentials'); Action = { Set-ToolboxRegistryValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0 } },
    @{ Id = 8; Category = 'Performance'; Name = 'Reduce visual effects'; Description = 'Prefer performance over visual effects for this user.'; Safe = $false; Presets = @('Performance'); Action = { Set-ToolboxRegistryValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 2 } }
)

$script:SelectedTweakIds = @{}
$script:VisibleTweaks = @()

function Save-ToolboxSelection {
    for ($i = 0; $i -lt $script:TweakList.Items.Count; $i++) {
        $tweak = $script:VisibleTweaks[$i]
        if ($script:TweakList.GetItemChecked($i)) {
            $script:SelectedTweakIds[[string]$tweak.Id] = $true
        } else {
            $script:SelectedTweakIds.Remove([string]$tweak.Id)
        }
    }
}

function Update-ToolboxList {
    if ($null -eq $script:TweakList) { return }
    Save-ToolboxSelection
    $script:TweakList.BeginUpdate()
    $script:TweakList.Items.Clear()
    $category = [string]$script:CategoryPicker.SelectedItem
    $query = $script:SearchBox.Text.Trim()
    $script:VisibleTweaks = @($script:ToolboxTweaks | Where-Object {
        ($category -eq 'All' -or $_.Category -eq $category) -and
        (-not $script:SafeModeBox.Checked -or $_.Safe) -and
        ([string]::IsNullOrWhiteSpace($query) -or $_.Name.IndexOf($query, [StringComparison]::OrdinalIgnoreCase) -ge 0 -or $_.Description.IndexOf($query, [StringComparison]::OrdinalIgnoreCase) -ge 0)
    })
    foreach ($tweak in $script:VisibleTweaks) {
        $riskLabel = if ($tweak.Safe) { 'SAFE' } else { 'REVIEW' }
        $index = $script:TweakList.Items.Add("[$riskLabel] $($tweak.Name)  —  $($tweak.Description)")
        $script:TweakList.SetItemChecked($index, $script:SelectedTweakIds.ContainsKey([string]$tweak.Id))
    }
    $script:TweakList.EndUpdate()
    $script:StatusLabel.Text = "$($script:VisibleTweaks.Count) tweak(s) shown. Nothing changes until you choose Apply."
}

function Select-ToolboxPreset {
    param([string]$Preset)
    $script:SelectedTweakIds = @{}
    foreach ($tweak in $script:ToolboxTweaks) {
        if ($tweak.Presets -contains $Preset -and (-not $script:SafeModeBox.Checked -or $tweak.Safe)) {
            $script:SelectedTweakIds[[string]$tweak.Id] = $true
        }
    }
    Update-ToolboxList
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Anki Toolbox — Windows Tweaks'
$form.StartPosition = 'CenterScreen'
$form.Size = New-Object System.Drawing.Size(900, 650)
$form.MinimumSize = New-Object System.Drawing.Size(780, 560)
$form.BackColor = [System.Drawing.Color]::FromArgb(20, 22, 32)
$form.ForeColor = [System.Drawing.Color]::White
$form.Font = New-Object System.Drawing.Font('Segoe UI', 9)

$title = New-Object System.Windows.Forms.Label
$title.Text = 'ANKI TOOLBOX'
$title.Location = New-Object System.Drawing.Point(22, 16)
$title.Size = New-Object System.Drawing.Size(420, 36)
$title.Font = New-Object System.Drawing.Font('Segoe UI', 19, [System.Drawing.FontStyle]::Bold)
$title.ForeColor = [System.Drawing.Color]::FromArgb(95, 205, 255)
$form.Controls.Add($title)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = 'Choose a preset or review individual Windows settings before applying.'
$subtitle.Location = New-Object System.Drawing.Point(24, 54)
$subtitle.Size = New-Object System.Drawing.Size(680, 24)
$subtitle.ForeColor = [System.Drawing.Color]::FromArgb(185, 190, 210)
$form.Controls.Add($subtitle)

$presetLabel = New-Object System.Windows.Forms.Label
$presetLabel.Text = 'QUICK PRESETS'
$presetLabel.Location = New-Object System.Drawing.Point(24, 91)
$presetLabel.Size = New-Object System.Drawing.Size(150, 25)
$presetLabel.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($presetLabel)

$essentialsButton = New-Object System.Windows.Forms.Button
$essentialsButton.Text = 'Essentials'
$essentialsButton.Location = New-Object System.Drawing.Point(175, 85)
$essentialsButton.Size = New-Object System.Drawing.Size(125, 34)
$essentialsButton.Add_Click({ Select-ToolboxPreset 'Essentials' })
$form.Controls.Add($essentialsButton)

$gamingButton = New-Object System.Windows.Forms.Button
$gamingButton.Text = 'Gaming'
$gamingButton.Location = New-Object System.Drawing.Point(310, 85)
$gamingButton.Size = New-Object System.Drawing.Size(125, 34)
$gamingButton.Add_Click({ Select-ToolboxPreset 'Gaming' })
$form.Controls.Add($gamingButton)

$performanceButton = New-Object System.Windows.Forms.Button
$performanceButton.Text = 'Performance'
$performanceButton.Location = New-Object System.Drawing.Point(445, 85)
$performanceButton.Size = New-Object System.Drawing.Size(125, 34)
$performanceButton.Add_Click({ Select-ToolboxPreset 'Performance' })
$form.Controls.Add($performanceButton)

$script:SafeModeBox = New-Object System.Windows.Forms.CheckBox
$script:SafeModeBox.Text = 'Safe mode (hide settings marked REVIEW)'
$script:SafeModeBox.Location = New-Object System.Drawing.Point(590, 90)
$script:SafeModeBox.Size = New-Object System.Drawing.Size(280, 24)
$script:SafeModeBox.Checked = $true
$script:SafeModeBox.Add_CheckedChanged({
    Save-ToolboxSelection
    if ($script:SafeModeBox.Checked) {
        foreach ($tweak in $script:ToolboxTweaks) {
            if (-not $tweak.Safe) { $script:SelectedTweakIds.Remove([string]$tweak.Id) }
        }
    }
    Update-ToolboxList
})
$form.Controls.Add($script:SafeModeBox)

$categoryLabel = New-Object System.Windows.Forms.Label
$categoryLabel.Text = 'Category:'
$categoryLabel.Location = New-Object System.Drawing.Point(24, 139)
$categoryLabel.Size = New-Object System.Drawing.Size(70, 24)
$form.Controls.Add($categoryLabel)

$script:CategoryPicker = New-Object System.Windows.Forms.ComboBox
$script:CategoryPicker.Location = New-Object System.Drawing.Point(95, 135)
$script:CategoryPicker.Size = New-Object System.Drawing.Size(190, 28)
$script:CategoryPicker.DropDownStyle = 'DropDownList'
[void]$script:CategoryPicker.Items.Add('All')
foreach ($category in ($script:ToolboxTweaks.Category | Sort-Object -Unique)) { [void]$script:CategoryPicker.Items.Add($category) }
$script:CategoryPicker.SelectedIndex = 0
$script:CategoryPicker.Add_SelectedIndexChanged({ Update-ToolboxList })
$form.Controls.Add($script:CategoryPicker)

$script:SearchBox = New-Object System.Windows.Forms.TextBox
$script:SearchBox.Location = New-Object System.Drawing.Point(305, 135)
$script:SearchBox.Size = New-Object System.Drawing.Size(565, 28)
$script:SearchBox.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$script:SearchBox.Add_TextChanged({ Update-ToolboxList })
$form.Controls.Add($script:SearchBox)

$script:TweakList = New-Object System.Windows.Forms.CheckedListBox
$script:TweakList.Location = New-Object System.Drawing.Point(24, 175)
$script:TweakList.Size = New-Object System.Drawing.Size(846, 350)
$script:TweakList.Anchor = 'Top, Bottom, Left, Right'
$script:TweakList.BackColor = [System.Drawing.Color]::FromArgb(31, 34, 47)
$script:TweakList.ForeColor = [System.Drawing.Color]::White
$script:TweakList.BorderStyle = 'FixedSingle'
$script:TweakList.CheckOnClick = $true
$script:TweakList.Add_ItemCheck({
    $index = $_.Index
    $newValue = $_.NewValue
    if ($index -ge 0 -and $index -lt $script:VisibleTweaks.Count) {
        $id = [string]$script:VisibleTweaks[$index].Id
        if ($newValue -eq [System.Windows.Forms.CheckState]::Checked) { $script:SelectedTweakIds[$id] = $true }
        else { $script:SelectedTweakIds.Remove($id) }
    }
})
$form.Controls.Add($script:TweakList)

$selectAllButton = New-Object System.Windows.Forms.Button
$selectAllButton.Text = 'Select shown'
$selectAllButton.Location = New-Object System.Drawing.Point(24, 540)
$selectAllButton.Size = New-Object System.Drawing.Size(120, 34)
$selectAllButton.Anchor = 'Bottom, Left'
$selectAllButton.Add_Click({
    foreach ($tweak in $script:VisibleTweaks) { $script:SelectedTweakIds[[string]$tweak.Id] = $true }
    Update-ToolboxList
})
$form.Controls.Add($selectAllButton)

$clearButton = New-Object System.Windows.Forms.Button
$clearButton.Text = 'Clear selection'
$clearButton.Location = New-Object System.Drawing.Point(154, 540)
$clearButton.Size = New-Object System.Drawing.Size(120, 34)
$clearButton.Anchor = 'Bottom, Left'
$clearButton.Add_Click({ $script:SelectedTweakIds = @{}; Update-ToolboxList })
$form.Controls.Add($clearButton)

$script:StatusLabel = New-Object System.Windows.Forms.Label
$script:StatusLabel.Location = New-Object System.Drawing.Point(290, 545)
$script:StatusLabel.Size = New-Object System.Drawing.Size(390, 30)
$script:StatusLabel.Anchor = 'Bottom, Left, Right'
$script:StatusLabel.ForeColor = [System.Drawing.Color]::FromArgb(180, 190, 205)
$script:StatusLabel.Text = 'Ready.'
$form.Controls.Add($script:StatusLabel)

$applyButton = New-Object System.Windows.Forms.Button
$applyButton.Text = 'Review & Apply'
$applyButton.Location = New-Object System.Drawing.Point(710, 540)
$applyButton.Size = New-Object System.Drawing.Size(160, 36)
$applyButton.Anchor = 'Bottom, Right'
$applyButton.BackColor = [System.Drawing.Color]::FromArgb(80, 190, 120)
$applyButton.ForeColor = [System.Drawing.Color]::Black
$applyButton.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
$applyButton.Add_Click({
    Save-ToolboxSelection
    $selected = @($script:ToolboxTweaks | Where-Object { $script:SelectedTweakIds.ContainsKey([string]$_.Id) })
    if ($selected.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show('Select at least one setting first.', 'Anki Toolbox', 'OK', 'Information') | Out-Null
        return
    }
    $names = ($selected | ForEach-Object { '- ' + $_.Name }) -join [Environment]::NewLine
    $answer = [System.Windows.Forms.MessageBox]::Show("Apply these $($selected.Count) setting(s)?`n`n$names`n`nOnly the listed registry settings will be changed. Review each setting before continuing.", 'Confirm changes', 'YesNo', 'Warning')
    if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) { return }

    $applied = 0
    $failed = New-Object System.Collections.Generic.List[string]
    foreach ($tweak in $selected) {
        try {
            & $tweak.Action
            $applied++
        } catch {
            $failed.Add($tweak.Name)
        }
    }
    if ($failed.Count -gt 0) {
        $script:StatusLabel.Text = "Applied $applied; failed: $($failed -join ', ')"
        [System.Windows.Forms.MessageBox]::Show("Applied $applied setting(s). These failed:`n$($failed -join [Environment]::NewLine)", 'Some settings failed', 'OK', 'Warning') | Out-Null
    } else {
        $script:StatusLabel.Text = "Successfully applied $applied setting(s)."
        [System.Windows.Forms.MessageBox]::Show("Successfully applied $applied setting(s). Some changes may require signing out or restarting Windows.", 'Done', 'OK', 'Information') | Out-Null
    }
})
$form.Controls.Add($applyButton)

Update-ToolboxList
[void]$form.ShowDialog()
