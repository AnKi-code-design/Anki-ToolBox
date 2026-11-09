Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

if (-not ([Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains 'S-1-5-32-544')) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

function Set-RegVal($Path, $Name, $Value, $Type = 'DWord') {
    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null
        }
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force -ErrorAction SilentlyContinue | Out-Null
    }
    catch {}
}

$Tweaks = @(
    @{ id = 1; name = 'Enable Dark Mode'; desc = 'Set dark theme for apps'; safe = $true; action = { Set-RegVal 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'AppsUseLightTheme' 0 } },
    @{ id = 2; name = 'Disable Start Menu Ads'; desc = 'Stop suggestions in Start menu'; safe = $true; action = { Set-RegVal 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions' 1 } },
    @{ id = 3; name = 'Disable Recent Files'; desc = 'Remove recent file history in Explorer'; safe = $true; action = { Set-RegVal 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer' 'ShowRecent' 0 } },
    @{ id = 4; name = 'Disable Game DVR'; desc = 'Turn off Game DVR capture'; safe = $false; action = { Set-RegVal 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0 } },
    @{ id = 5; name = 'Disable Telemetry'; desc = 'Turns off basic diagnostic tracking'; safe = $false; action = { Set-RegVal 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0 } },
    @{ id = 6; name = 'Disable Transparency'; desc = 'Improve FPS and reduce visual effects'; safe = $true; action = { Set-RegVal 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 0 } }
)

$form = New-Object System.Windows.Forms.Form
$form.Text = 'AnkiToolbox Pro'
$form.Size = New-Object System.Drawing.Size(720, 520)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(18, 18, 26)
$form.ForeColor = [System.Drawing.Color]::White
$form.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$title = New-Object System.Windows.Forms.Label
$title.Text = 'ANKI TOOLBOX'
title.Location = New-Object System.Drawing.Point(20, 20)
title.Size = New-Object System.Drawing.Size(320, 30)
title.Font = New-Object System.Drawing.Font('Segoe UI', 16, [System.Drawing.FontStyle]::Bold)
title.ForeColor = [System.Drawing.Color]::FromArgb(100, 220, 255)
$form.Controls.Add($title)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = 'Windows cleanup and performance tweaks'
$subtitle.Location = New-Object System.Drawing.Point(20, 52)
$subtitle.Size = New-Object System.Drawing.Size(400, 20)
$subtitle.ForeColor = [System.Drawing.Color]::FromArgb(180, 180, 210)
$form.Controls.Add($subtitle)

$checkList = New-Object System.Windows.Forms.CheckedListBox
$checkList.Location = New-Object System.Drawing.Point(20, 90)
$checkList.Size = New-Object System.Drawing.Size(660, 300)
$checkList.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 45)
$checkList.ForeColor = [System.Drawing.Color]::White
$checkList.BorderStyle = 'FixedSingle'

foreach ($t in $Tweaks) {
    $checkList.Items.Add($t.name) | Out-Null
}
$form.Controls.Add($checkList)

$selectAllBtn = New-Object System.Windows.Forms.Button
$selectAllBtn.Text = 'Select All'
$selectAllBtn.Location = New-Object System.Drawing.Point(20, 410)
$selectAllBtn.Size = New-Object System.Drawing.Size(110, 36)
$selectAllBtn.Add_Click({
    for ($i = 0; $i -lt $checkList.Items.Count; $i++) { $checkList.SetItemChecked($i, $true) }
})
$form.Controls.Add($selectAllBtn)

$clearBtn = New-Object System.Windows.Forms.Button
$clearBtn.Text = 'Clear All'
$clearBtn.Location = New-Object System.Drawing.Point(145, 410)
$clearBtn.Size = New-Object System.Drawing.Size(110, 36)
$clearBtn.Add_Click({
    for ($i = 0; $i -lt $checkList.Items.Count; $i++) { $checkList.SetItemChecked($i, $false) }
})
$form.Controls.Add($clearBtn)

$applyBtn = New-Object System.Windows.Forms.Button
$applyBtn.Text = 'Apply Selected'
$applyBtn.Location = New-Object System.Drawing.Point(520, 410)
$applyBtn.Size = New-Object System.Drawing.Size(160, 36)
$applyBtn.BackColor = [System.Drawing.Color]::FromArgb(100, 200, 100)
$applyBtn.ForeColor = [System.Drawing.Color]::Black
$applyBtn.Add_Click({
    $selected = @()
    for ($i = 0; $i -lt $checkList.Items.Count; $i++) {
        if ($checkList.GetItemChecked($i)) {
            $selected += $Tweaks[$i]
        }
    }

    if ($selected.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show('Select at least one tweak first.', 'Info', 'OK', 'Information') | Out-Null
        return
    }

    foreach ($t in $selected) {
        & $t.action
    }

    [System.Windows.Forms.MessageBox]::Show("Applied $($selected.Count) tweak(s). Restart recommended.", 'Success', 'OK', 'Information') | Out-Null
})
$form.Controls.Add($applyBtn)

$form.ShowDialog() | Out-Null
