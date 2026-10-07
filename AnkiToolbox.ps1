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
#  TWEAKS DEFINITION
# ============================================================

function Set-RegVal($Path, $Name, $Value, $Type = "DWord") {
    try {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force -EA 0 | Out-Null }
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force -EA 0 | Out-Null
    } catch {}
}

$Tweaks = @(
    # Gaming Performance
    @{ id = 1; cat = "🎮 Gaming"; name = "Disable Game DVR"; desc = "Xbox Game Bar recording"; preset = @('Advanced', 'Ultra'); action = { Set-RegVal "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0 } },
    @{ id = 2; cat = "🎮 Gaming"; name = "Enable Game Mode"; desc = "Prioritize foreground game"; preset = @('Advanced', 'Ultra'); action = { Set-RegVal "HKCU:\Software\Microsoft\GameBar" "AllowAutoGameMode" 1 } },
    @{ id = 3; cat = "🎮 Gaming"; name = "GPU Hardware Scheduling"; desc = "Accelerated GPU scheduling"; preset = @('Advanced', 'Ultra'); action = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2 } },
    @{ id = 4; cat = "🎮 Gaming"; name = "Disable Fullscreen Optimization"; desc = "Reduce input lag"; preset = @('Advanced', 'Ultra'); action = { Set-RegVal "HKCU:\System\GameConfigStore" "GameDVR_FSEBehavior" 2 } },
    @{ id = 5; cat = "🎮 Gaming"; name = "Disable Xbox Overlay"; desc = "Remove Xbox Game Bar"; preset = @('Advanced', 'Ultra'); action = { Set-RegVal "HKCU:\Software\Microsoft\XboxGameOverlay" "GameOverlayEnabled" 0 } },

    # System Performance
    @{ id = 11; cat = "⚡ System"; name = "Disable Visual Effects"; desc = "Remove animations"; preset = @('Balanced', 'Advanced', 'Ultra'); action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 2 } },
    @{ id = 12; cat = "⚡ System"; name = "Disable Animations"; desc = "All transitions off"; preset = @('Advanced', 'Ultra'); action = { Set-RegVal "HKCU:\Control Panel\Desktop" "DragFullWindows" "0" "String"; Set-RegVal "HKCU:\Control Panel\Desktop" "MenuShowDelay" "0" "String" } },
    @{ id = 13; cat = "⚡ System"; name = "Disable Cortana"; desc = "Remove Cortana"; preset = @('Minimal', 'Balanced', 'Advanced', 'Ultra'); action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "CortanaConsent" 0 } },
    @{ id = 14; cat = "⚡ System"; name = "Disable Cloud Sync"; desc = "Local only"; preset = @('Minimal', 'Balanced', 'Advanced'); action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync" "SyncPolicy" 0 } },
    @{ id = 15; cat = "⚡ System"; name = "Disable Tips"; desc = "No suggestions"; preset = @('Minimal', 'Balanced'); action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SoftLandingEnabled" 0 } },

    # Network & Speed
    @{ id = 21; cat = "🌐 Network"; name = "Disable Nagle"; desc = "Lower network latency"; preset = @('Advanced', 'Ultra'); action = { Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -EA 0 | ForEach-Object { Set-RegVal $_.PSPath "TcpAckFrequency" 1; Set-RegVal $_.PSPath "TCPNoDelay" 1 } } },
    @{ id = 22; cat = "🌐 Network"; name = "Full Bandwidth"; desc = "Disable throttling"; preset = @('Advanced', 'Ultra'); action = { Set-RegVal "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 4294967295 } },
    @{ id = 23; cat = "🌐 Network"; name = "TCP Auto-Tuning"; desc = "Optimize TCP window"; preset = @('Balanced', 'Advanced', 'Ultra'); action = { netsh int tcp set global autotuninglevel=normal 2>$null | Out-Null } },
    @{ id = 24; cat = "🌐 Network"; name = "Enable TCP RSS"; desc = "Multi-core network"; preset = @('Advanced', 'Ultra'); action = { netsh int tcp set global rss=enabled 2>$null | Out-Null } },
    @{ id = 25; cat = "🌐 Network"; name = "TCP Fast Open"; desc = "Faster connections"; preset = @('Advanced', 'Ultra'); action = { netsh int tcp set global fastopen=enabled 2>$null | Out-Null } },

    # Services
    @{ id = 31; cat = "🛑 Services"; name = "Disable Windows Update"; desc = "Stop auto updates"; preset = @('Advanced', 'Ultra'); action = { Stop-Service -Name wuauserv -Force -EA 0; Set-Service -Name wuauserv -StartupType Disabled -EA 0 } },
    @{ id = 32; cat = "🛑 Services"; name = "Disable Windows Search"; desc = "Stop indexing"; preset = @('Minimal', 'Balanced', 'Advanced', 'Ultra'); action = { Stop-Service -Name WSearch -Force -EA 0; Set-Service -Name WSearch -StartupType Disabled -EA 0 } },
    @{ id = 33; cat = "🛑 Services"; name = "Disable Superfetch"; desc = "Stop memory caching"; preset = @('Balanced', 'Advanced', 'Ultra'); action = { Stop-Service -Name SysMain -Force -EA 0; Set-Service -Name SysMain -StartupType Disabled -EA 0 } },
    @{ id = 34; cat = "🛑 Services"; name = "Disable Telemetry"; desc = "Stop data collection"; preset = @('Minimal', 'Balanced', 'Advanced', 'Ultra'); action = { Stop-Service -Name DiagTrack -Force -EA 0; Set-Service -Name DiagTrack -StartupType Disabled -EA 0 } },
    @{ id = 35; cat = "🛑 Services"; name = "Disable BITS"; desc = "Stop downloads"; preset = @('Advanced', 'Ultra'); action = { Stop-Service -Name BITS -Force -EA 0; Set-Service -Name BITS -StartupType Disabled -EA 0 } },

    # Disk & Cleanup
    @{ id = 41; cat = "💾 Disk"; name = "Clean Temp Files"; desc = "Remove temp files"; preset = @('Minimal', 'Balanced', 'Advanced', 'Ultra'); action = { Remove-Item -Path "$env:temp\*" -Recurse -Force -EA 0 | Out-Null } },
    @{ id = 42; cat = "💾 Disk"; name = "Clear Recycle Bin"; desc = "Empty trash"; preset = @('Balanced', 'Advanced', 'Ultra'); action = { Clear-RecycleBin -Force -EA 0 } },
    @{ id = 43; cat = "💾 Disk"; name = "Disable Prefetch"; desc = "No app prefetch"; preset = @('Advanced', 'Ultra'); action = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" "EnablePrefetcher" 0 } },
    @{ id = 44; cat = "💾 Disk"; name = "Enable SSD TRIM"; desc = "Optimize SSD"; preset = @('Balanced', 'Advanced', 'Ultra'); action = { fsutil behavior set DisableDeleteNotify 0 2>$null | Out-Null } },
    @{ id = 45; cat = "💾 Disk"; name = "Disable Hibernation"; desc = "Remove hibernation file"; preset = @('Balanced', 'Advanced'); action = { powercfg /hibernate off 2>$null | Out-Null } },

    # UI & Experience
    @{ id = 51; cat = "🎨 UI"; name = "Enable Dark Mode"; desc = "Dark theme"; preset = @('Minimal', 'Balanced'); action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme" 0; Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "SystemUsesLightTheme" 0 } },
    @{ id = 52; cat = "🎨 UI"; name = "Hide Recently Used"; desc = "Clean recent files"; preset = @('Minimal', 'Balanced'); action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" "ShowRecent" 0 } },
    @{ id = 53; cat = "🎨 UI"; name = "No Start Menu Ads"; desc = "Disable suggestions"; preset = @('Minimal', 'Balanced'); action = { Set-RegVal "HKCU:\Software\Policies\Microsoft\Windows\Explorer" "DisableSearchBoxSuggestions" 1 } },
    @{ id = 54; cat = "🎨 UI"; name = "Disable Aero Peek"; desc = "Fast window preview"; preset = @('Advanced', 'Ultra'); action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\DWM" "DisableFullWindowDrag" 1 } },
    @{ id = 55; cat = "🎨 UI"; name = "Hide Recycle Bin"; desc = "Clean desktop"; preset = @('Minimal'); action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowRecycleBinFullNotification" 0 } },

    # Privacy & Security
    @{ id = 61; cat = "🔒 Privacy"; name = "Disable Activity History"; desc = "No timeline data"; preset = @('Minimal', 'Balanced', 'Advanced', 'Ultra'); action = { Set-RegVal "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" 0 } },
    @{ id = 62; cat = "🔒 Privacy"; name = "Disable Advertising ID"; desc = "No ad tracking"; preset = @('Minimal', 'Balanced', 'Advanced', 'Ultra'); action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0 } },
    @{ id = 63; cat = "🔒 Privacy"; name = "Disable Microphone"; desc = "Apps can't use mic"; preset = @('Minimal', 'Advanced'); action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" "MicrophoneEnabled" 0 } },
    @{ id = 64; cat = "🔒 Privacy"; name = "Disable Camera"; desc = "Apps can't use camera"; preset = @('Minimal', 'Advanced'); action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" "CameraEnabled" 0 } },
    @{ id = 65; cat = "🔒 Privacy"; name = "Disable Spotlight Ads"; desc = "No lock screen ads"; preset = @('Minimal', 'Balanced'); action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "RotatingLockScreenEnabled" 0 } },

    # Advanced Tweaks
    @{ id = 71; cat = "⚙️ Advanced"; name = "Increase File Cache"; desc = "Disk cache boost"; preset = @('Advanced', 'Ultra'); action = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "CcPfThreshold" 64 } },
    @{ id = 72; cat = "⚙️ Advanced"; name = "Mouse Sensitivity"; desc = "Instant response"; preset = @('Advanced', 'Ultra'); action = { Set-RegVal "HKCU:\Control Panel\Mouse" "MouseSensitivity" "10" "String" } },
    @{ id = 73; cat = "⚙️ Advanced"; name = "Reduce Boot Time"; desc = "Faster startup"; preset = @('Balanced', 'Advanced', 'Ultra'); action = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "ClearPageFileAtShutdown" 0 } },
    @{ id = 74; cat = "⚙️ Advanced"; name = "Disable Aero Snap"; desc = "No window snapping"; preset = @('Advanced', 'Ultra'); action = { Set-RegVal "HKCU:\Control Panel\Desktop" "WindowArrangementStyle" "Cascade" "String" } },
    @{ id = 75; cat = "⚙️ Advanced"; name = "Lower Latency"; desc = "Minimal lag"; preset = @('Advanced', 'Ultra'); action = { netsh int tcp set global autotuninglevel=restricted 2>$null | Out-Null } }
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
    }
    "Balanced" = @{
        desc = "Performance + Privacy"
        color = [System.Drawing.Color]::FromArgb(144, 238, 144)
    }
    "Advanced" = @{
        desc = "Gaming + Performance"
        color = [System.Drawing.Color]::FromArgb(255, 165, 0)
    }
    "Ultra" = @{
        desc = "Maximum Performance"
        color = [System.Drawing.Color]::FromArgb(255, 69, 0)
    }
}

# ============================================================
#  MODERN GUI FORM
# ============================================================

$form = New-Object System.Windows.Forms.Form
$form.Text = "AnkiToolbox - Windows Optimizer"
$form.Size = New-Object System.Drawing.Size(1400, 900)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 35)
$form.ForeColor = [System.Drawing.Color]::White
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$form.FormBorderStyle = "Sizable"
$form.Icon = $null

# =========== HEADER ===========
$header = New-Object System.Windows.Forms.Panel
$header.Location = New-Object System.Drawing.Point(0, 0)
$header.Size = New-Object System.Drawing.Size(1400, 100)
$header.BackColor = [System.Drawing.Color]::FromArgb(15, 15, 25)
$header.BorderStyle = "FixedSingle"
$form.Controls.Add($header)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "⚡ ANKI'S TOOLBOX"
$titleLabel.Location = New-Object System.Drawing.Point(20, 15)
$titleLabel.Size = New-Object System.Drawing.Size(300, 35)
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(100, 200, 255)
$header.Controls.Add($titleLabel)

$subtitleLabel = New-Object System.Windows.Forms.Label
$subtitleLabel.Text = "Windows Performance Optimizer | 75+ Tweaks"
$subtitleLabel.Location = New-Object System.Drawing.Point(20, 50)
$subtitleLabel.Size = New-Object System.Drawing.Size(500, 25)
$subtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$subtitleLabel.ForeColor = [System.Drawing.Color]::FromArgb(150, 150, 170)
$header.Controls.Add($subtitleLabel)

# =========== PRESET BUTTONS ===========
$presetPanel = New-Object System.Windows.Forms.Panel
$presetPanel.Location = New-Object System.Drawing.Point(0, 100)
$presetPanel.Size = New-Object System.Drawing.Size(1400, 80)
$presetPanel.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 30)
$presetPanel.BorderStyle = "FixedSingle"
$form.Controls.Add($presetPanel)

$presetLabel = New-Object System.Windows.Forms.Label
$presetLabel.Text = "QUICK PRESETS:"
$presetLabel.Location = New-Object System.Drawing.Point(20, 12)
$presetLabel.Size = New-Object System.Drawing.Size(150, 25)
$presetLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$presetLabel.ForeColor = [System.Drawing.Color]::White
$presetPanel.Controls.Add($presetLabel)

$x = 180
$presetButtons = @{}
foreach ($preset in $Presets.Keys) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $preset
    $btn.Location = New-Object System.Drawing.Point($x, 10)
    $btn.Size = New-Object System.Drawing.Size(140, 50)
    $btn.BackColor = $Presets[$preset].color
    $btn.ForeColor = [System.Drawing.Color]::Black
    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 0
    $btn.Cursor = "Hand"
    $btn.Tag = $preset
    $btn.Add_Click({
        Apply-Preset $this.Tag
    })
    $presetPanel.Controls.Add($btn)
    $presetButtons[$preset] = $btn
    $x += 150
}

# =========== MAIN CONTENT ===========
$contentPanel = New-Object System.Windows.Forms.Panel
$contentPanel.Location = New-Object System.Drawing.Point(0, 180)
$contentPanel.Size = New-Object System.Drawing.Size(200, 640)
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
    $btn.Size = New-Object System.Drawing.Size(185, 35)
    $btn.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 60)
    $btn.ForeColor = [System.Drawing.Color]::FromArgb(180, 180, 200)
    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 1
    $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(80, 80, 120)
    $btn.Cursor = "Hand"
    $btn.Tag = $cat
    $btn.Add_Click({
        Update-TweakDisplay $this.Tag
    })
    $contentPanel.Controls.Add($btn)
    $y += 40
}

# =========== TWEAKS DISPLAY ===========
$tweakPanel = New-Object System.Windows.Forms.Panel
$tweakPanel.Location = New-Object System.Drawing.Point(200, 180)
$tweakPanel.Size = New-Object System.Drawing.Size(1200, 640)
$tweakPanel.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 35)
$tweakPanel.BorderStyle = "FixedSingle"
$tweakPanel.AutoScroll = $true
$form.Controls.Add($tweakPanel)

# Search box
$searchBox = New-Object System.Windows.Forms.TextBox
$searchBox.Location = New-Object System.Drawing.Point(10, 10)
$searchBox.Size = New-Object System.Drawing.Size(1170, 30)
$searchBox.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 60)
$searchBox.ForeColor = [System.Drawing.Color]::White
$searchBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$searchBox.BorderStyle = "FixedSingle"
$searchBox.PlaceholderText = "🔍 Search tweaks..."
$searchBox.Add_TextChanged({
    Update-TweakDisplay $currentCategory
})
$tweakPanel.Controls.Add($searchBox)

# =========== BOTTOM BUTTONS ===========
$footerPanel = New-Object System.Windows.Forms.Panel
$footerPanel.Location = New-Object System.Drawing.Point(0, 820)
$footerPanel.Size = New-Object System.Drawing.Size(1400, 50)
$footerPanel.BackColor = [System.Drawing.Color]::FromArgb(15, 15, 25)
$footerPanel.BorderStyle = "FixedSingle"
$form.Controls.Add($footerPanel)

# Status label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(10, 15)
$statusLabel.Size = New-Object System.Drawing.Size(800, 25)
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(100, 200, 100)
$statusLabel.Text = "Ready"
$footerPanel.Controls.Add($statusLabel)

# Apply button
$applyBtn = New-Object System.Windows.Forms.Button
$applyBtn.Text = "✓ Apply Selected"
$applyBtn.Location = New-Object System.Drawing.Point(820, 8)
$applyBtn.Size = New-Object System.Drawing.Size(150, 35)
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
    $result = [System.Windows.Forms.MessageBox]::Show("Apply $($selected.Count) tweaks?`nRestart recommended after.", "Confirm", "YesNo", "Question")
    if ($result -eq "Yes") {
        $statusLabel.Text = "Applying tweaks..."
        $form.Refresh()
        foreach ($id in $selected) {
            $tweak = $Tweaks | Where-Object { $_.id -eq $id }
            if ($tweak) { & $tweak.action }
        }
        $statusLabel.Text = "✓ Applied $($selected.Count) tweaks! Consider restarting."
        [System.Windows.Forms.MessageBox]::Show("✓ $($selected.Count) tweaks applied!`nRestart for best results.", "Success", "OK", "Information") | Out-Null
    }
})
$footerPanel.Controls.Add($applyBtn)

# Restart button
$restartBtn = New-Object System.Windows.Forms.Button
$restartBtn.Text = "🔄 Restart"
$restartBtn.Location = New-Object System.Drawing.Point(980, 8)
$restartBtn.Size = New-Object System.Drawing.Size(110, 35)
$restartBtn.BackColor = [System.Drawing.Color]::FromArgb(200, 100, 100)
$restartBtn.ForeColor = [System.Drawing.Color]::White
$restartBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$restartBtn.FlatStyle = "Flat"
$restartBtn.Cursor = "Hand"
$restartBtn.Add_Click({
    $result = [System.Windows.Forms.MessageBox]::Show("Restart now?", "Confirm", "YesNo", "Question")
    if ($result -eq "Yes") { Restart-Computer -Force }
})
$footerPanel.Controls.Add($restartBtn)

# Exit button
$exitBtn = New-Object System.Windows.Forms.Button
$exitBtn.Text = "✕ Exit"
$exitBtn.Location = New-Object System.Drawing.Point(1100, 8)
$exitBtn.Size = New-Object System.Drawing.Size(110, 35)
$exitBtn.BackColor = [System.Drawing.Color]::FromArgb(100, 100, 140)
$exitBtn.ForeColor = [System.Drawing.Color]::White
$exitBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$exitBtn.FlatStyle = "Flat"
$exitBtn.Cursor = "Hand"
$exitBtn.Add_Click({ $form.Close() })
$footerPanel.Controls.Add($exitBtn)

# =========== FUNCTIONS ===========
$script:tweakCheckboxes = @{}
$script:currentCategory = $null

function Update-TweakDisplay($category) {
    $script:currentCategory = $category
    $tweakPanel.Controls.Clear()
    
    # Re-add search box
    $tweakPanel.Controls.Add($searchBox)
    
    $search = $searchBox.Text.ToLower()
    $filtered = $Categories[$category] | Where-Object { 
        $_.name.ToLower().Contains($search) -or $_.desc.ToLower().Contains($search)
    }
    
    $y = 50
    foreach ($tweak in $filtered) {
        # Checkbox
        $chk = New-Object System.Windows.Forms.CheckBox
        $chk.Location = New-Object System.Drawing.Point(10, $y)
        $chk.Size = New-Object System.Drawing.Size(20, 20)
        $chk.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 35)
        $chk.ForeColor = [System.Drawing.Color]::White
        $tweakPanel.Controls.Add($chk)
        $script:tweakCheckboxes[$tweak.id] = $chk
        
        # Name label
        $nameLabel = New-Object System.Windows.Forms.Label
        $nameLabel.Location = New-Object System.Drawing.Point(40, $y - 2)
        $nameLabel.Size = New-Object System.Drawing.Size(300, 25)
        $nameLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $nameLabel.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 220)
        $nameLabel.Text = $tweak.name
        $tweakPanel.Controls.Add($nameLabel)
        
        # Description label
        $descLabel = New-Object System.Windows.Forms.Label
        $descLabel.Location = New-Object System.Drawing.Point(40, $y + 18)
        $descLabel.Size = New-Object System.Drawing.Size(800, 20)
        $descLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
        $descLabel.ForeColor = [System.Drawing.Color]::FromArgb(150, 150, 170)
        $descLabel.Text = $tweak.desc
        $tweakPanel.Controls.Add($descLabel)
        
        # Preset tags
        $presets = $tweak.preset -join ", "
        $presetLabel = New-Object System.Windows.Forms.Label
        $presetLabel.Location = New-Object System.Drawing.Point(900, $y)
        $presetLabel.Size = New-Object System.Drawing.Size(250, 25)
        $presetLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
        $presetLabel.ForeColor = [System.Drawing.Color]::FromArgb(100, 200, 255)
        $presetLabel.Text = "Presets: $presets"
        $presetLabel.TextAlign = "MiddleRight"
        $tweakPanel.Controls.Add($presetLabel)
        
        $y += 50
    }
    
    # Update category button highlight
    foreach ($btn in $contentPanel.Controls | Where-Object { $_ -is [System.Windows.Forms.Button] }) {
        if ($btn.Tag -eq $category) {
            $btn.BackColor = [System.Drawing.Color]::FromArgb(100, 150, 200)
            $btn.ForeColor = [System.Drawing.Color]::Black
        } else {
            $btn.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 60)
            $btn.ForeColor = [System.Drawing.Color]::FromArgb(180, 180, 200)
        }
    }
    
    $statusLabel.Text = "Showing $($filtered.Count) tweaks in $category"
}

function Apply-Preset($presetName) {
    $tweaks = $Tweaks | Where-Object { $_.preset -contains $presetName }
    if ($tweaks.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No tweaks for this preset.", "Info", "OK", "Information") | Out-Null
        return
    }
    
    $result = [System.Windows.Forms.MessageBox]::Show("Apply $presetName preset?`n$($tweaks.Count) tweaks will be applied.`n`nRestart recommended.", "Confirm", "YesNo", "Question")
    if ($result -eq "Yes") {
        $statusLabel.Text = "Applying $presetName preset..."
        $form.Refresh()
        
        foreach ($tweak in $tweaks) {
            & $tweak.action
        }
        
        $statusLabel.Text = "✓ Applied $presetName preset! ($($tweaks.Count) tweaks)"
        [System.Windows.Forms.MessageBox]::Show("✓ $presetName preset applied!`n$($tweaks.Count) tweaks activated.`nRestart recommended.", "Success", "OK", "Information") | Out-Null
    }
}

# Initialize display
Update-TweakDisplay ($Categories.Keys | Sort-Object)[0]

$form.ShowDialog() | Out-Null
