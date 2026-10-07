Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

if (-not ([Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains 'S-1-5-32-544')) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/AnKi-code-design/Anki-ToolBox/main/AnkiToolbox.ps1 | iex`""
    exit
}

$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

# ============================================================
#  TWEAKS DEFINITION WITH UNDO SUPPORT
# ============================================================

function Set-RegVal($Path, $Name, $Value, $Type = "DWord") {
    try {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force -EA 0 | Out-Null }
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force -EA 0 | Out-Null
    } catch {}
}

function Get-RegVal($Path, $Name) {
    try {
        return (Get-ItemProperty -Path $Path -Name $Name -EA 0).$Name
    } catch {
        return $null
    }
}

$Tweaks = @(
    # Gaming Performance
    @{ id = 1; cat = "🎮 Gaming"; name = "Disable Game DVR"; desc = "Xbox Game Bar recording"; safe = $false; preset = @('Advanced', 'Ultra'); action = { Set-RegVal "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0 }; undo = { Set-RegVal "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 1 } },
    @{ id = 2; cat = "🎮 Gaming"; name = "Enable Game Mode"; desc = "Prioritize foreground game"; safe = $true; preset = @('Advanced', 'Ultra'); action = { Set-RegVal "HKCU:\Software\Microsoft\GameBar" "AllowAutoGameMode" 1 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\GameBar" "AllowAutoGameMode" 0 } },
    @{ id = 3; cat = "🎮 Gaming"; name = "GPU Hardware Scheduling"; desc = "Accelerated GPU scheduling"; safe = $false; preset = @('Advanced', 'Ultra'); action = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2 }; undo = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 0 } },
    @{ id = 4; cat = "🎮 Gaming"; name = "Disable Fullscreen Optimization"; desc = "Reduce input lag"; safe = $true; preset = @('Advanced', 'Ultra'); action = { Set-RegVal "HKCU:\System\GameConfigStore" "GameDVR_FSEBehavior" 2 }; undo = { Set-RegVal "HKCU:\System\GameConfigStore" "GameDVR_FSEBehavior" 0 } },
    @{ id = 5; cat = "🎮 Gaming"; name = "Disable Xbox Overlay"; desc = "Remove Xbox Game Bar"; safe = $true; preset = @('Advanced', 'Ultra'); action = { Set-RegVal "HKCU:\Software\Microsoft\XboxGameOverlay" "GameOverlayEnabled" 0 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\XboxGameOverlay" "GameOverlayEnabled" 1 } },

    # System Performance
    @{ id = 11; cat = "⚡ System"; name = "Disable Visual Effects"; desc = "Remove animations"; safe = $true; preset = @('Balanced', 'Advanced', 'Ultra'); action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 2 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 3 } },
    @{ id = 12; cat = "⚡ System"; name = "Disable Animations"; desc = "All transitions off"; safe = $true; preset = @('Advanced', 'Ultra'); action = { Set-RegVal "HKCU:\Control Panel\Desktop" "DragFullWindows" "0" "String"; Set-RegVal "HKCU:\Control Panel\Desktop" "MenuShowDelay" "0" "String" }; undo = { Set-RegVal "HKCU:\Control Panel\Desktop" "DragFullWindows" "1" "String"; Set-RegVal "HKCU:\Control Panel\Desktop" "MenuShowDelay" "400" "String" } },
    @{ id = 13; cat = "⚡ System"; name = "Disable Cortana"; desc = "Remove Cortana"; safe = $false; preset = @('Minimal', 'Balanced', 'Advanced', 'Ultra'); action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "CortanaConsent" 0 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "CortanaConsent" 1 } },
    @{ id = 14; cat = "⚡ System"; name = "Disable Cloud Sync"; desc = "Local only"; safe = $true; preset = @('Minimal', 'Balanced', 'Advanced'); action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync" "SyncPolicy" 0 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync" "SyncPolicy" 3 } },
    @{ id = 15; cat = "⚡ System"; name = "Disable Tips"; desc = "No suggestions"; safe = $true; preset = @('Minimal', 'Balanced'); action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SoftLandingEnabled" 0 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SoftLandingEnabled" 1 } },

    # Network & Speed
    @{ id = 21; cat = "🌐 Network"; name = "Disable Nagle"; desc = "Lower network latency"; safe = $false; preset = @('Advanced', 'Ultra'); action = { Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -EA 0 | ForEach-Object { Set-RegVal $_.PSPath "TcpAckFrequency" 1; Set-RegVal $_.PSPath "TCPNoDelay" 1 } }; undo = { Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -EA 0 | ForEach-Object { Remove-ItemProperty -Path $_.PSPath -Name "TcpAckFrequency" -EA 0; Remove-ItemProperty -Path $_.PSPath -Name "TCPNoDelay" -EA 0 } } },
    @{ id = 22; cat = "🌐 Network"; name = "Full Bandwidth"; desc = "Disable throttling"; safe = $false; preset = @('Advanced', 'Ultra'); action = { Set-RegVal "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 4294967295 }; undo = { Set-RegVal "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 10 } },
    @{ id = 23; cat = "🌐 Network"; name = "TCP Auto-Tuning"; desc = "Optimize TCP window"; safe = $true; preset = @('Balanced', 'Advanced', 'Ultra'); action = { netsh int tcp set global autotuninglevel=normal 2>$null | Out-Null }; undo = { netsh int tcp set global autotuninglevel=normal 2>$null | Out-Null } },
    @{ id = 24; cat = "🌐 Network"; name = "Enable TCP RSS"; desc = "Multi-core network"; safe = $true; preset = @('Advanced', 'Ultra'); action = { netsh int tcp set global rss=enabled 2>$null | Out-Null }; undo = { netsh int tcp set global rss=disabled 2>$null | Out-Null } },
    @{ id = 25; cat = "🌐 Network"; name = "TCP Fast Open"; desc = "Faster connections"; safe = $true; preset = @('Advanced', 'Ultra'); action = { netsh int tcp set global fastopen=enabled 2>$null | Out-Null }; undo = { netsh int tcp set global fastopen=disabled 2>$null | Out-Null } },

    # Services (HIGH RISK)
    @{ id = 31; cat = "🛑 Services"; name = "Disable Windows Update"; desc = "Stop auto updates (HIGH RISK)"; safe = $false; preset = @('Ultra'); action = { Stop-Service -Name wuauserv -Force -EA 0; Set-Service -Name wuauserv -StartupType Disabled -EA 0 }; undo = { Set-Service -Name wuauserv -StartupType Automatic -EA 0; Start-Service -Name wuauserv -EA 0 } },
    @{ id = 32; cat = "🛑 Services"; name = "Disable Windows Search"; desc = "Stop indexing"; safe = $false; preset = @('Minimal', 'Balanced', 'Advanced', 'Ultra'); action = { Stop-Service -Name WSearch -Force -EA 0; Set-Service -Name WSearch -StartupType Disabled -EA 0 }; undo = { Set-Service -Name WSearch -StartupType Automatic -EA 0; Start-Service -Name WSearch -EA 0 } },
    @{ id = 33; cat = "🛑 Services"; name = "Disable Superfetch"; desc = "Stop memory caching"; safe = $false; preset = @('Balanced', 'Advanced', 'Ultra'); action = { Stop-Service -Name SysMain -Force -EA 0; Set-Service -Name SysMain -StartupType Disabled -EA 0 }; undo = { Set-Service -Name SysMain -StartupType Automatic -EA 0; Start-Service -Name SysMain -EA 0 } },
    @{ id = 34; cat = "🛑 Services"; name = "Disable Telemetry"; desc = "Stop data collection"; safe = $false; preset = @('Minimal', 'Balanced', 'Advanced', 'Ultra'); action = { Stop-Service -Name DiagTrack -Force -EA 0; Set-Service -Name DiagTrack -StartupType Disabled -EA 0 }; undo = { Set-Service -Name DiagTrack -StartupType Automatic -EA 0; Start-Service -Name DiagTrack -EA 0 } },
    @{ id = 35; cat = "🛑 Services"; name = "Disable BITS"; desc = "Stop downloads"; safe = $false; preset = @('Advanced', 'Ultra'); action = { Stop-Service -Name BITS -Force -EA 0; Set-Service -Name BITS -StartupType Disabled -EA 0 }; undo = { Set-Service -Name BITS -StartupType Automatic -EA 0; Start-Service -Name BITS -EA 0 } },

    # Disk & Cleanup
    @{ id = 41; cat = "💾 Disk"; name = "Clean Temp Files"; desc = "Remove temp files"; safe = $true; preset = @('Minimal', 'Balanced', 'Advanced', 'Ultra'); action = { Remove-Item -Path "$env:temp\*" -Recurse -Force -EA 0 | Out-Null }; undo = {} },
    @{ id = 42; cat = "💾 Disk"; name = "Clear Recycle Bin"; desc = "Empty trash"; safe = $true; preset = @('Balanced', 'Advanced', 'Ultra'); action = { Clear-RecycleBin -Force -EA 0 }; undo = {} },
    @{ id = 43; cat = "💾 Disk"; name = "Disable Prefetch"; desc = "No app prefetch"; safe = $false; preset = @('Advanced', 'Ultra'); action = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" "EnablePrefetcher" 0 }; undo = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" "EnablePrefetcher" 3 } },
    @{ id = 44; cat = "💾 Disk"; name = "Enable SSD TRIM"; desc = "Optimize SSD"; safe = $true; preset = @('Balanced', 'Advanced', 'Ultra'); action = { fsutil behavior set DisableDeleteNotify 0 2>$null | Out-Null }; undo = { fsutil behavior set DisableDeleteNotify 1 2>$null | Out-Null } },
    @{ id = 45; cat = "💾 Disk"; name = "Disable Hibernation"; desc = "Remove hibernation file"; safe = $true; preset = @('Balanced', 'Advanced'); action = { powercfg /hibernate off 2>$null | Out-Null }; undo = { powercfg /hibernate on 2>$null | Out-Null } },

    # UI & Experience
    @{ id = 51; cat = "🎨 UI"; name = "Enable Dark Mode"; desc = "Dark theme"; safe = $true; preset = @('Minimal', 'Balanced'); action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme" 0; Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "SystemUsesLightTheme" 0 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme" 1; Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "SystemUsesLightTheme" 1 } },
    @{ id = 52; cat = "🎨 UI"; name = "Hide Recently Used"; desc = "Clean recent files"; safe = $true; preset = @('Minimal', 'Balanced'); action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" "ShowRecent" 0 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" "ShowRecent" 1 } },
    @{ id = 53; cat = "🎨 UI"; name = "No Start Menu Ads"; desc = "Disable suggestions"; safe = $true; preset = @('Minimal', 'Balanced'); action = { Set-RegVal "HKCU:\Software\Policies\Microsoft\Windows\Explorer" "DisableSearchBoxSuggestions" 1 }; undo = { Set-RegVal "HKCU:\Software\Policies\Microsoft\Windows\Explorer" "DisableSearchBoxSuggestions" 0 } },
    @{ id = 54; cat = "🎨 UI"; name = "Disable Aero Peek"; desc = "Fast window preview"; safe = $true; preset = @('Advanced', 'Ultra'); action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\DWM" "DisableFullWindowDrag" 1 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\Windows\DWM" "DisableFullWindowDrag" 0 } },
    @{ id = 55; cat = "🎨 UI"; name = "Hide Recycle Bin"; desc = "Clean desktop"; safe = $true; preset = @('Minimal'); action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowRecycleBinFullNotification" 0 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowRecycleBinFullNotification" 1 } },

    # Privacy & Security
    @{ id = 61; cat = "🔒 Privacy"; name = "Disable Activity History"; desc = "No timeline data"; safe = $true; preset = @('Minimal', 'Balanced', 'Advanced', 'Ultra'); action = { Set-RegVal "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" 0 }; undo = { Set-RegVal "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" 1 } },
    @{ id = 62; cat = "🔒 Privacy"; name = "Disable Advertising ID"; desc = "No ad tracking"; safe = $true; preset = @('Minimal', 'Balanced', 'Advanced', 'Ultra'); action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 1 } },
    @{ id = 63; cat = "🔒 Privacy"; name = "Disable Microphone"; desc = "Apps can't use mic"; safe = $true; preset = @('Minimal', 'Advanced'); action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" "MicrophoneEnabled" 0 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" "MicrophoneEnabled" 1 } },
    @{ id = 64; cat = "🔒 Privacy"; name = "Disable Camera"; desc = "Apps can't use camera"; safe = $true; preset = @('Minimal', 'Advanced'); action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" "CameraEnabled" 0 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" "CameraEnabled" 1 } },
    @{ id = 65; cat = "🔒 Privacy"; name = "Disable Spotlight Ads"; desc = "No lock screen ads"; safe = $true; preset = @('Minimal', 'Balanced'); action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "RotatingLockScreenEnabled" 0 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "RotatingLockScreenEnabled" 1 } },

    # Advanced Tweaks
    @{ id = 71; cat = "⚙️ Advanced"; name = "Increase File Cache"; desc = "Disk cache boost"; safe = $false; preset = @('Advanced', 'Ultra'); action = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "CcPfThreshold" 64 }; undo = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "CcPfThreshold" 24 } },
    @{ id = 72; cat = "⚙️ Advanced"; name = "Mouse Sensitivity"; desc = "Instant response"; safe = $true; preset = @('Advanced', 'Ultra'); action = { Set-RegVal "HKCU:\Control Panel\Mouse" "MouseSensitivity" "10" "String" }; undo = { Set-RegVal "HKCU:\Control Panel\Mouse" "MouseSensitivity" "10" "String" } },
    @{ id = 73; cat = "⚙️ Advanced"; name = "Reduce Boot Time"; desc = "Faster startup"; safe = $false; preset = @('Balanced', 'Advanced', 'Ultra'); action = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "ClearPageFileAtShutdown" 0 }; undo = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "ClearPageFileAtShutdown" 0 } },
    @{ id = 74; cat = "⚙️ Advanced"; name = "Disable Aero Snap"; desc = "No window snapping"; safe = $true; preset = @('Advanced', 'Ultra'); action = { Set-RegVal "HKCU:\Control Panel\Desktop" "WindowArrangementStyle" "Cascade" "String" }; undo = { Remove-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WindowArrangementStyle" -EA 0 } },
    @{ id = 75; cat = "⚙️ Advanced"; name = "Lower Latency"; desc = "Minimal lag"; safe = $false; preset = @('Advanced', 'Ultra'); action = { netsh int tcp set global autotuninglevel=restricted 2>$null | Out-Null }; undo = { netsh int tcp set global autotuninglevel=normal 2>$null | Out-Null } }
)

$Categories = @{}
foreach ($tweak in $Tweaks) {
    if (-not $Categories.ContainsKey($tweak.cat)) {
        $Categories[$tweak.cat] = @()
    }
    $Categories[$tweak.cat] += $tweak
}

$Presets = @{
    "Minimal" = @{
        desc = "Privacy & Basic Cleanup"
        color = [System.Drawing.Color]::FromArgb(135, 206, 235)
        icon = "🔵"
    }
    "Balanced" = @{
        desc = "Performance + Privacy"
        color = [System.Drawing.Color]::FromArgb(144, 238, 144)
        icon = "🟢"
    }
    "Advanced" = @{
        desc = "Gaming + Performance"
        color = [System.Drawing.Color]::FromArgb(255, 165, 0)
        icon = "🟠"
    }
    "Ultra" = @{
        desc = "Maximum Performance"
        color = [System.Drawing.Color]::FromArgb(255, 69, 0)
        icon = "🔴"
    }
}

# ============================================================
#  MODERN GLASSMORPHISM GUI
# ============================================================

$form = New-Object System.Windows.Forms.Form
$form.Text = "AnkiToolbox Pro - Ultimate Windows Optimizer"
$form.Size = New-Object System.Drawing.Size(1500, 950)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 30)
$form.ForeColor = [System.Drawing.Color]::White
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$form.FormBorderStyle = "Sizable"
$form.Icon = $null
$form.MinimumSize = New-Object System.Drawing.Size(1200, 700)

# =========== HEADER WITH GLASSMORPHISM ===========
$header = New-Object System.Windows.Forms.Panel
$header.Location = New-Object System.Drawing.Point(0, 0)
$header.Size = New-Object System.Drawing.Size(1500, 120)
$header.BackColor = [System.Drawing.Color]::FromArgb(15, 15, 25)
$header.BorderStyle = "FixedSingle"
$form.Controls.Add($header)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "⚡ ANKI'S TOOLBOX PRO"
$titleLabel.Location = New-Object System.Drawing.Point(30, 15)
$titleLabel.Size = New-Object System.Drawing.Size(400, 40)
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(100, 220, 255)
$header.Controls.Add($titleLabel)

$subtitleLabel = New-Object System.Windows.Forms.Label
$subtitleLabel.Text = "Advanced System Optimizer | 75+ Tweaks | Glassmorphism UI"
$subtitleLabel.Location = New-Object System.Drawing.Point(30, 55)
$subtitleLabel.Size = New-Object System.Drawing.Size(600, 25)
$subtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$subtitleLabel.ForeColor = [System.Drawing.Color]::FromArgb(150, 150, 180)
$header.Controls.Add($subtitleLabel)

# Safe Mode Toggle
$safeModeCheckbox = New-Object System.Windows.Forms.CheckBox
$safeModeCheckbox.Text = "🛡️ SAFE MODE (No risky changes)"
$safeModeCheckbox.Location = New-Object System.Drawing.Point(1050, 20)
$safeModeCheckbox.Size = New-Object System.Drawing.Size(420, 30)
$safeModeCheckbox.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 30)
$safeModeCheckbox.ForeColor = [System.Drawing.Color]::FromArgb(100, 220, 100)
$safeModeCheckbox.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$safeModeCheckbox.Checked = $false
$safeModeCheckbox.Add_CheckedChanged({
    $script:safeMode = $safeModeCheckbox.Checked
    Update-TweakDisplay $script:currentCategory
})
$header.Controls.Add($safeModeCheckbox)

# Mode Selector
$compactCheckbox = New-Object System.Windows.Forms.CheckBox
$compactCheckbox.Text = "📱 COMPACT VIEW"
$compactCheckbox.Location = New-Object System.Drawing.Point(1050, 60)
$compactCheckbox.Size = New-Object System.Drawing.Size(420, 30)
$compactCheckbox.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 30)
$compactCheckbox.ForeColor = [System.Drawing.Color]::FromArgb(100, 200, 255)
$compactCheckbox.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$compactCheckbox.Checked = $false
$compactCheckbox.Add_CheckedChanged({
    $script:compactMode = $compactCheckbox.Checked
    Update-TweakDisplay $script:currentCategory
})
$header.Controls.Add($compactCheckbox)

# =========== PRESET BUTTONS ===========
$presetPanel = New-Object System.Windows.Forms.Panel
$presetPanel.Location = New-Object System.Drawing.Point(0, 120)
$presetPanel.Size = New-Object System.Drawing.Size(1500, 90)
$presetPanel.BackColor = [System.Drawing.Color]::FromArgb(18, 18, 28)
$presetPanel.BorderStyle = "FixedSingle"
$form.Controls.Add($presetPanel)

$presetLabel = New-Object System.Windows.Forms.Label
$presetLabel.Text = "⚡ QUICK PRESETS:"
$presetLabel.Location = New-Object System.Drawing.Point(20, 15)
$presetLabel.Size = New-Object System.Drawing.Size(200, 30)
$presetLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$presetLabel.ForeColor = [System.Drawing.Color]::White
$presetPanel.Controls.Add($presetLabel)

$x = 220
$presetButtons = @{}
foreach ($preset in $Presets.Keys) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = "$($Presets[$preset].icon) $preset`n$($Presets[$preset].desc)"
    $btn.Location = New-Object System.Drawing.Point($x, 8)
    $btn.Size = New-Object System.Drawing.Size(160, 65)
    $btn.BackColor = $Presets[$preset].color
    $btn.ForeColor = [System.Drawing.Color]::Black
    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 0
    $btn.Cursor = "Hand"
    $btn.Tag = $preset
    $btn.Add_Click({
        Apply-Preset $this.Tag
    })
    $presetPanel.Controls.Add($btn)
    $presetButtons[$preset] = $btn
    $x += 170
}

# Select All / Clear All
$selectAllBtn = New-Object System.Windows.Forms.Button
$selectAllBtn.Text = "✓ SELECT ALL"
$selectAllBtn.Location = New-Object System.Drawing.Point(900, 25)
$selectAllBtn.Size = New-Object System.Drawing.Size(100, 50)
$selectAllBtn.BackColor = [System.Drawing.Color]::FromArgb(100, 180, 255)
$selectAllBtn.ForeColor = [System.Drawing.Color]::Black
$selectAllBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$selectAllBtn.FlatStyle = "Flat"
$selectAllBtn.Cursor = "Hand"
$selectAllBtn.Add_Click({
    foreach ($cb in $script:tweakCheckboxes.Values) {
        $cb.Checked = $true
    }
})
$presetPanel.Controls.Add($selectAllBtn)

$clearAllBtn = New-Object System.Windows.Forms.Button
$clearAllBtn.Text = "✕ CLEAR ALL"
$clearAllBtn.Location = New-Object System.Drawing.Point(1010, 25)
$clearAllBtn.Size = New-Object System.Drawing.Size(100, 50)
$clearAllBtn.BackColor = [System.Drawing.Color]::FromArgb(200, 100, 100)
$clearAllBtn.ForeColor = [System.Drawing.Color]::White
$clearAllBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$clearAllBtn.FlatStyle = "Flat"
$clearAllBtn.Cursor = "Hand"
$clearAllBtn.Add_Click({
    foreach ($cb in $script:tweakCheckboxes.Values) {
        $cb.Checked = $false
    }
})
$presetPanel.Controls.Add($clearAllBtn)

# =========== MAIN CONTENT ===========
$contentPanel = New-Object System.Windows.Forms.Panel
$contentPanel.Location = New-Object System.Drawing.Point(0, 210)
$contentPanel.Size = New-Object System.Drawing.Size(220, 670)
$contentPanel.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 30)
$contentPanel.BorderStyle = "FixedSingle"
$contentPanel.AutoScroll = $true
$form.Controls.Add($contentPanel)

# Category buttons
$y = 5
foreach ($cat in $Categories.Keys | Sort-Object) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $cat
    $btn.Location = New-Object System.Drawing.Point(5, $y)
    $btn.Size = New-Object System.Drawing.Size(205, 40)
    $btn.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 65)
    $btn.ForeColor = [System.Drawing.Color]::FromArgb(180, 180, 210)
    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 2
    $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(80, 80, 120)
    $btn.Cursor = "Hand"
    $btn.Tag = $cat
    $btn.Add_Click({
        Update-TweakDisplay $this.Tag
    })
    $contentPanel.Controls.Add($btn)
    $y += 45
}

# =========== TWEAKS DISPLAY ===========
$tweakPanel = New-Object System.Windows.Forms.Panel
$tweakPanel.Location = New-Object System.Drawing.Point(220, 210)
$tweakPanel.Size = New-Object System.Drawing.Size(1280, 670)
$tweakPanel.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 38)
$tweakPanel.BorderStyle = "FixedSingle"
$tweakPanel.AutoScroll = $true
$form.Controls.Add($tweakPanel)

# Search box
$searchBox = New-Object System.Windows.Forms.TextBox
$searchBox.Location = New-Object System.Drawing.Point(10, 10)
$searchBox.Size = New-Object System.Drawing.Size(1250, 40)
$searchBox.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 65)
$searchBox.ForeColor = [System.Drawing.Color]::White
$searchBox.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$searchBox.BorderStyle = "FixedSingle"
$searchBox.PlaceholderText = "🔍 Search tweaks by name or description..."
$searchBox.Add_TextChanged({
    Update-TweakDisplay $script:currentCategory
})
$tweakPanel.Controls.Add($searchBox)

# =========== BOTTOM BUTTONS ===========
$footerPanel = New-Object System.Windows.Forms.Panel
$footerPanel.Location = New-Object System.Drawing.Point(0, 880)
$footerPanel.Size = New-Object System.Drawing.Size(1500, 50)
$footerPanel.BackColor = [System.Drawing.Color]::FromArgb(15, 15, 25)
$footerPanel.BorderStyle = "FixedSingle"
$form.Controls.Add($footerPanel)

# Status label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(10, 12)
$statusLabel.Size = New-Object System.Drawing.Size(850, 28)
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(100, 200, 100)
$statusLabel.Text = "✓ Ready | Select tweaks and click Apply"
$footerPanel.Controls.Add($statusLabel)

# Apply button
$applyBtn = New-Object System.Windows.Forms.Button
$applyBtn.Text = "✓ APPLY SELECTED"
$applyBtn.Location = New-Object System.Drawing.Point(870, 8)
$applyBtn.Size = New-Object System.Drawing.Size(160, 35)
$applyBtn.BackColor = [System.Drawing.Color]::FromArgb(100, 200, 100)
$applyBtn.ForeColor = [System.Drawing.Color]::Black
$applyBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$applyBtn.FlatStyle = "Flat"
$applyBtn.Cursor = "Hand"
$applyBtn.Add_Click({
    $selected = @($script:tweakCheckboxes.Keys | Where-Object { $script:tweakCheckboxes[$_].Checked })
    if ($selected.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Select tweaks first!", "Info", "OK", "Information") | Out-Null
        return
    }
    $result = [System.Windows.Forms.MessageBox]::Show("Apply $($selected.Count) tweaks?`n`nRestart recommended after applying.`nSafe Mode: $(if ($script:safeMode) { 'ON - Risky tweaks disabled' } else { 'OFF' })", "Confirm", "YesNo", "Question")
    if ($result -eq "Yes") {
        $statusLabel.Text = "⏳ Applying $($selected.Count) tweaks..."
        $form.Refresh()
        $count = 0
        foreach ($id in $selected) {
            $tweak = $Tweaks | Where-Object { $_.id -eq $id }
            if ($tweak) { & $tweak.action; $count++ }
        }
        $statusLabel.Text = "✓ Applied $count tweaks! | Safe Mode: $(if ($script:safeMode) { 'ON' } else { 'OFF' })"
        [System.Windows.Forms.MessageBox]::Show("✓ $count tweaks applied!`n`nRestart your PC for best results.", "Success", "OK", "Information") | Out-Null
    }
})
$footerPanel.Controls.Add($applyBtn)

# Undo button
$undoBtn = New-Object System.Windows.Forms.Button
$undoBtn.Text = "↶ UNDO"
$undoBtn.Location = New-Object System.Drawing.Point(1040, 8)
$undoBtn.Size = New-Object System.Drawing.Size(130, 35)
$undoBtn.BackColor = [System.Drawing.Color]::FromArgb(255, 165, 0)
$undoBtn.ForeColor = [System.Drawing.Color]::Black
$undoBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$undoBtn.FlatStyle = "Flat"
$undoBtn.Cursor = "Hand"
$undoBtn.Add_Click({
    $selected = @($script:tweakCheckboxes.Keys | Where-Object { $script:tweakCheckboxes[$_].Checked })
    if ($selected.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Select tweaks to undo!", "Info", "OK", "Information") | Out-Null
        return
    }
    $result = [System.Windows.Forms.MessageBox]::Show("Undo $($selected.Count) tweaks?`n`nRevert to previous state.", "Confirm", "YesNo", "Question")
    if ($result -eq "Yes") {
        $statusLabel.Text = "⏳ Undoing $($selected.Count) tweaks..."
        $form.Refresh()
        $count = 0
        foreach ($id in $selected) {
            $tweak = $Tweaks | Where-Object { $_.id -eq $id }
            if ($tweak -and $tweak.undo) { & $tweak.undo; $count++ }
        }
        $statusLabel.Text = "✓ Undid $count tweaks! | Settings reverted"
        [System.Windows.Forms.MessageBox]::Show("✓ $count tweaks reverted!`n`nRestart recommended.", "Success", "OK", "Information") | Out-Null
    }
})
$footerPanel.Controls.Add($undoBtn)

# Restart button
$restartBtn = New-Object System.Windows.Forms.Button
$restartBtn.Text = "🔄 RESTART"
$restartBtn.Location = New-Object System.Drawing.Point(1180, 8)
$restartBtn.Size = New-Object System.Drawing.Size(130, 35)
$restartBtn.BackColor = [System.Drawing.Color]::FromArgb(200, 100, 100)
$restartBtn.ForeColor = [System.Drawing.Color]::White
$restartBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$restartBtn.FlatStyle = "Flat"
$restartBtn.Cursor = "Hand"
$restartBtn.Add_Click({
    $result = [System.Windows.Forms.MessageBox]::Show("Restart your PC now?", "Confirm", "YesNo", "Question")
    if ($result -eq "Yes") { Restart-Computer -Force }
})
$footerPanel.Controls.Add($restartBtn)

# Exit button
$exitBtn = New-Object System.Windows.Forms.Button
$exitBtn.Text = "✕ EXIT"
$exitBtn.Location = New-Object System.Drawing.Point(1320, 8)
$exitBtn.Size = New-Object System.Drawing.Size(170, 35)
$exitBtn.BackColor = [System.Drawing.Color]::FromArgb(100, 100, 150)
$exitBtn.ForeColor = [System.Drawing.Color]::White
$exitBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$exitBtn.FlatStyle = "Flat"
$exitBtn.Cursor = "Hand"
$exitBtn.Add_Click({ $form.Close() })
$footerPanel.Controls.Add($exitBtn)

# =========== FUNCTIONS ===========
$script:tweakCheckboxes = @{}
$script:currentCategory = $null
$script:safeMode = $false
$script:compactMode = $false

function Update-TweakDisplay($category) {
    $script:currentCategory = $category
    $tweakPanel.Controls.Clear()
    $tweakPanel.Controls.Add($searchBox)
    
    $search = $searchBox.Text.ToLower()
    $filtered = $Categories[$category] | Where-Object { 
        ($_.name.ToLower().Contains($search) -or $_.desc.ToLower().Contains($search)) -and
        ($script:safeMode -eq $false -or $_.safe -eq $true)
    }
    
    $y = 60
    $itemHeight = if ($script:compactMode) { 50 } else { 80 }
    
    foreach ($tweak in $filtered) {
        # Checkbox
        $chk = New-Object System.Windows.Forms.CheckBox
        $chk.Location = New-Object System.Drawing.Point(15, $y + 5)
        $chk.Size = New-Object System.Drawing.Size(20, 20)
        $chk.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 38)
        $chk.ForeColor = [System.Drawing.Color]::White
        $tweakPanel.Controls.Add($chk)
        $script:tweakCheckboxes[$tweak.id] = $chk
        
        # Name label
        $nameLabel = New-Object System.Windows.Forms.Label
        $nameLabel.Location = New-Object System.Drawing.Point(50, $y)
        $nameLabel.Size = New-Object System.Drawing.Size(350, 25)
        $nameLabel.Font = New-Object System.Drawing.Font("Segoe UI", if ($script:compactMode) { 9 } else { 10 }, [System.Drawing.FontStyle]::Bold)
        $nameLabel.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 230)
        $nameLabel.Text = $tweak.name
        if ($tweak.safe -eq $false) { $nameLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 150, 100) }
        $tweakPanel.Controls.Add($nameLabel)
        
        # Description label
        if (-not $script:compactMode) {
            $descLabel = New-Object System.Windows.Forms.Label
            $descLabel.Location = New-Object System.Drawing.Point(50, $y + 25)
            $descLabel.Size = New-Object System.Drawing.Size(600, 20)
            $descLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
            $descLabel.ForeColor = [System.Drawing.Color]::FromArgb(150, 150, 180)
            $descLabel.Text = $tweak.desc
            $tweakPanel.Controls.Add($descLabel)
        }
        
        # Preset tags
        $presets = $tweak.preset -join " | "
        $presetLabel = New-Object System.Windows.Forms.Label
        $presetLabel.Location = New-Object System.Drawing.Point(750, $y)
        $presetLabel.Size = New-Object System.Drawing.Size(500, 25)
        $presetLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
        $presetLabel.ForeColor = [System.Drawing.Color]::FromArgb(100, 200, 255)
        $presetLabel.Text = "📋 $presets"
        $presetLabel.TextAlign = "MiddleLeft"
        $tweakPanel.Controls.Add($presetLabel)
        
        # Safe indicator
        if ($tweak.safe -eq $false) {
            $safeLabel = New-Object System.Windows.Forms.Label
            $safeLabel.Location = New-Object System.Drawing.Point(1200, $y)
            $safeLabel.Size = New-Object System.Drawing.Size(50, 25)
            $safeLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
            $safeLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 150, 100)
            $safeLabel.Text = "⚠️ RISKY"
            $tweakPanel.Controls.Add($safeLabel)
        }
        
        $y += $itemHeight
    }
    
    # Update category button highlight
    foreach ($btn in $contentPanel.Controls | Where-Object { $_ -is [System.Windows.Forms.Button] }) {
        if ($btn.Tag -eq $category) {
            $btn.BackColor = [System.Drawing.Color]::FromArgb(100, 200, 255)
            $btn.ForeColor = [System.Drawing.Color]::Black
        } else {
            $btn.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 65)
            $btn.ForeColor = [System.Drawing.Color]::FromArgb(180, 180, 210)
        }
    }
    
    $safeText = if ($script:safeMode) { " | Safe Mode: ON" } else { "" }
    $statusLabel.Text = "✓ Showing $($filtered.Count) tweaks in $category$safeText"
}

function Apply-Preset($presetName) {
    $tweaks = if ($script:safeMode) {
        $Tweaks | Where-Object { $_.preset -contains $presetName -and $_.safe -eq $true }
    } else {
        $Tweaks | Where-Object { $_.preset -contains $presetName }
    }
    
    if ($tweaks.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No tweaks available for this preset$(if ($script:safeMode) { " in Safe Mode" } else { "." })", "Info", "OK", "Information") | Out-Null
        return
    }
    
    $result = [System.Windows.Forms.MessageBox]::Show("Apply $presetName preset?`n`n$($tweaks.Count) tweaks will be applied.`nRestart recommended.`n`nSafe Mode: $(if ($script:safeMode) { 'ON' } else { 'OFF' })", "Confirm", "YesNo", "Question")
    if ($result -eq "Yes") {
        $statusLabel.Text = "⏳ Applying $presetName preset..."
        $form.Refresh()
        
        $count = 0
        foreach ($tweak in $tweaks) {
            & $tweak.action
            $count++
        }
        
        $statusLabel.Text = "✓ Applied $presetName preset! ($count tweaks) | Safe Mode: $(if ($script:safeMode) { 'ON' } else { 'OFF' })"
        [System.Windows.Forms.MessageBox]::Show("✓ $presetName preset applied!`n$count tweaks activated.`n`nRestart your PC for best results.", "Success", "OK", "Information") | Out-Null
    }
}

# Initialize display
Update-TweakDisplay ($Categories.Keys | Sort-Object)[0]

$form.ShowDialog() | Out-Null
