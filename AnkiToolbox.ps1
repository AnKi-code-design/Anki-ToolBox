Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Admin Check
if (-not ([Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains 'S-1-5-32-544')) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/AnKi-code-design/Anki-ToolBox/main/AnkiToolbox.ps1 | iex`""
    exit
}

# Suppress errors
$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

# Global Variables
$script:CurrentCategory = 0
$script:AllTweaks = @()

# Registry Helper
function Set-RegVal($Path, $Name, $Value, $Type = "DWord") {
    try {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force -EA 0 | Out-Null }
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force -EA 0 | Out-Null
    } catch {}
}

# All 100 Tweaks Organized by Category
$Categories = @{
    "System Performance" = @(
        @{ id = 1; name = "Disable Game DVR"; action = { Set-RegVal "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0; Set-RegVal "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 0 } },
        @{ id = 2; name = "Enable Game Mode"; action = { Set-RegVal "HKCU:\Software\Microsoft\GameBar" "AllowAutoGameMode" 1 } },
        @{ id = 3; name = "GPU Hardware Scheduling"; action = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2 } },
        @{ id = 4; name = "Ultimate Performance Plan"; action = { powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null | Out-Null; $p = powercfg /list 2>$null | Select-String "Ultimate"; if ($p) { powercfg /setactive ($p.ToString() -split '\s+')[3] 2>$null } } },
        @{ id = 5; name = "Disable Visual Effects"; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 2 } },
        @{ id = 6; name = "Disable Window Animations"; action = { Set-RegVal "HKCU:\Control Panel\Desktop" "DragFullWindows" "0" "String"; Set-RegVal "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "0" "String" } },
        @{ id = 7; name = "Disable Taskbar Animations"; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations" 0 } },
        @{ id = 8; name = "Disable Menu Animations"; action = { Set-RegVal "HKCU:\Control Panel\Desktop" "MenuShowDelay" "0" "String" } },
        @{ id = 9; name = "Disable Explorer Animations"; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ListviewAlphaSelect" 0; Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ListviewShadow" 0 } },
        @{ id = 10; name = "MMCSS Priority Tuning"; action = { $p = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Set-RegVal $p "Priority" 6; Set-RegVal $p "GPU Priority" 8; Set-RegVal "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 0 } },
        @{ id = 11; name = "Disable Fullscreen Optimizations"; action = { Set-RegVal "HKCU:\System\GameConfigStore" "GameDVR_FSEBehavior" 2 } },
        @{ id = 12; name = "Disable Xbox Game Bar"; action = { Set-RegVal "HKCU:\Software\Microsoft\XboxGameOverlay" "GameOverlayEnabled" 0 } },
        @{ id = 13; name = "Disable Xbox DVR"; action = { Set-RegVal "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0 } },
        @{ id = 14; name = "Auto-Managed Page File"; action = { try { $cs = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges -EA 0; if ($cs) { $cs.AutomaticManagedPagefile = $true; $cs.Put() | Out-Null } } catch {} } },
        @{ id = 15; name = "Disable Cortana"; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "CortanaConsent" 0; Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 0 } },
        @{ id = 16; name = "Disable Windows Tips"; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SoftLandingEnabled" 0 } },
        @{ id = 17; name = "Disable Activity History"; action = { Set-RegVal "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" 0 } },
        @{ id = 18; name = "Disable Cloud Sync"; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync" "SyncPolicy" 0 } },
        @{ id = 19; name = "Disable Diagnostic Tracking"; action = { Stop-Service -Name DiagTrack -Force -EA 0; Set-Service -Name DiagTrack -StartupType Disabled -EA 0 } },
        @{ id = 20; name = "Disable dmwappushservice"; action = { Stop-Service -Name dmwappushservice -Force -EA 0; Set-Service -Name dmwappushservice -StartupType Disabled -EA 0 } }
    );
    
    "Network & Connectivity" = @(
        @{ id = 21; name = "Disable Nagle Algorithm"; action = { Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -EA 0 | ForEach-Object { Set-RegVal $_.PSPath "TcpAckFrequency" 1; Set-RegVal $_.PSPath "TCPNoDelay" 1 } } },
        @{ id = 22; name = "Disable Network Throttling"; action = { Set-RegVal "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 0xffffffff } },
        @{ id = 23; name = "TCP Auto-Tuning"; action = { netsh int tcp set global autotuninglevel=normal 2>$null | Out-Null } },
        @{ id = 24; name = "Disable TCP Chimney"; action = { netsh int tcp set global chimney=disabled 2>$null | Out-Null } },
        @{ id = 25; name = "Enable TCP RSS"; action = { netsh int tcp set global rss=enabled 2>$null | Out-Null } },
        @{ id = 26; name = "Disable ECN"; action = { netsh int tcp set global ecncapability=disabled 2>$null | Out-Null } },
        @{ id = 27; name = "Set Cloudflare DNS"; action = { Get-NetAdapter -EA 0 | Where-Object { $_.Status -eq "Up" } | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses ("1.1.1.1", "1.0.0.1") -EA 0 }; ipconfig /flushdns 2>$null | Out-Null } },
        @{ id = 28; name = "Set Google DNS"; action = { Get-NetAdapter -EA 0 | Where-Object { $_.Status -eq "Up" } | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses ("8.8.8.8", "8.8.4.4") -EA 0 }; ipconfig /flushdns 2>$null | Out-Null } },
        @{ id = 29; name = "Disable QoS Reservation"; action = { Set-RegVal "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" "NonBestEffortLimit" 0 } },
        @{ id = 30; name = "Disable IPv6"; action = { Get-NetAdapter -EA 0 | Where-Object { $_.Status -eq "Up" } | ForEach-Object { Disable-NetAdapterBinding -InterfaceAlias $_.Name -ComponentID ms_tcpip6 -EA 0 } } },
        @{ id = 31; name = "Disable NIC Power Saving"; action = { Get-NetAdapter -EA 0 | ForEach-Object { Disable-NetAdapterPowerManagement -Name $_.Name -EA 0 } } },
        @{ id = 32; name = "Enable TCP Fast Open"; action = { netsh int tcp set global fastopen=enabled 2>$null | Out-Null } },
        @{ id = 33; name = "Reduce TCP Retransmissions"; action = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpMaxDataRetransmissions" 3 } },
        @{ id = 34; name = "Disable LMHOSTS Lookup"; action = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" "EnableLMHOSTS" 0 } },
        @{ id = 35; name = "Enable NetDMA"; action = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "EnableTCPA" 1 } },
        @{ id = 36; name = "Optimize Network Buffers"; action = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpWindowSize" 65535 } },
        @{ id = 37; name = "Disable Network Adapter Sleep"; action = { Get-NetAdapter -EA 0 | ForEach-Object { Disable-NetAdapterPowerManagement -Name $_.Name -EA 0 } } },
        @{ id = 38; name = "Enable Offload Checksums"; action = { netsh int tcp set global autotuninglevel=normal 2>$null | Out-Null } },
        @{ id = 39; name = "Disable Teredo"; action = { netsh interface teredo set state disabled 2>$null | Out-Null } },
        @{ id = 40; name = "Disable ISATAP"; action = { netsh interface isatap set state disabled 2>$null | Out-Null } }
    );
    
    "Background Services" = @(
        @{ id = 41; name = "Disable Windows Search"; action = { Stop-Service -Name WSearch -Force -EA 0; Set-Service -Name WSearch -StartupType Disabled -EA 0 } },
        @{ id = 42; name = "Disable Superfetch"; action = { Stop-Service -Name SysMain -Force -EA 0; Set-Service -Name SysMain -StartupType Disabled -EA 0 } },
        @{ id = 43; name = "Disable Windows Update"; action = { Stop-Service -Name wuauserv -Force -EA 0; Set-Service -Name wuauserv -StartupType Disabled -EA 0 } },
        @{ id = 44; name = "Disable Update Orchestrator"; action = { Stop-Service -Name UsoSvc -Force -EA 0; Set-Service -Name UsoSvc -StartupType Disabled -EA 0 } },
        @{ id = 45; name = "Disable BITS"; action = { Stop-Service -Name BITS -Force -EA 0; Set-Service -Name BITS -StartupType Disabled -EA 0 } },
        @{ id = 46; name = "Disable Windows Defender"; action = { Set-RegVal "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" "DisableAntiSpyware" 1 } },
        @{ id = 47; name = "Disable Firewall"; action = { Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled $false -EA 0 } },
        @{ id = 48; name = "Disable Print Spooler"; action = { Stop-Service -Name Spooler -Force -EA 0; Set-Service -Name Spooler -StartupType Disabled -EA 0 } },
        @{ id = 49; name = "Disable Remote Assistance"; action = { Stop-Service -Name RasMan -Force -EA 0; Set-Service -Name RasMan -StartupType Disabled -EA 0 } },
        @{ id = 50; name = "Disable Bluetooth"; action = { Stop-Service -Name bthserv -Force -EA 0; Set-Service -Name bthserv -StartupType Disabled -EA 0 } },
        @{ id = 51; name = "Disable Hyper-V"; action = { Disable-WindowsOptionalFeature -Online -FeatureName Hyper-V -NoRestart -EA 0 } },
        @{ id = 52; name = "Disable VPN"; action = { Stop-Service -Name RasAuto -Force -EA 0; Set-Service -Name RasAuto -StartupType Disabled -EA 0 } },
        @{ id = 53; name = "Disable Remote Desktop"; action = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" "fDenyTSConnections" 1 } },
        @{ id = 54; name = "Disable Sharing"; action = { Stop-Service -Name LanmanServer -Force -EA 0; Set-Service -Name LanmanServer -StartupType Disabled -EA 0 } },
        @{ id = 55; name = "Disable Bluetooth Audio"; action = { Stop-Service -Name bthavctpsvc -Force -EA 0; Set-Service -Name bthavctpsvc -StartupType Disabled -EA 0 } },
        @{ id = 56; name = "Disable NFC"; action = { Stop-Service -Name NfcServ -Force -EA 0; Set-Service -Name NfcServ -StartupType Disabled -EA 0 } },
        @{ id = 57; name = "Disable Sensor Monitoring"; action = { Stop-Service -Name SensorService -Force -EA 0; Set-Service -Name SensorService -StartupType Disabled -EA 0 } },
        @{ id = 58; name = "Disable Location Services"; action = { Stop-Service -Name lfsvc -Force -EA 0; Set-Service -Name lfsvc -StartupType Disabled -EA 0 } },
        @{ id = 59; name = "Disable Connected User Experience"; action = { Stop-Service -Name DiagTrack -Force -EA 0; Set-Service -Name DiagTrack -StartupType Disabled -EA 0 } },
        @{ id = 60; name = "Disable App Telemetry"; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackProgs" 0 } }
    );
    
    "Disk & Storage" = @(
        @{ id = 61; name = "Clean Temp Files"; action = { Remove-Item -Path "$env:temp\*" -Recurse -Force -EA 0 | Out-Null; Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -EA 0 | Out-Null } },
        @{ id = 62; name = "Clear Recycle Bin"; action = { Clear-RecycleBin -Force -EA 0 } },
        @{ id = 63; name = "Disable Disk Indexing"; action = { $disk = Get-WmiObject Win32_LogicalDisk -Filter "DriveType = 3" -EA 0; $disk | ForEach-Object { $_.IndexingEnabled = $false; $_.Put() | Out-Null } } },
        @{ id = 64; name = "Optimize Drives"; action = { Optimize-Volume -DriveLetter C -Defrag -EA 0 } },
        @{ id = 65; name = "Enable TRIM"; action = { fsutil behavior set DisableDeleteNotify 0 2>$null | Out-Null } },
        @{ id = 66; name = "Disable Prefetch"; action = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" "EnablePrefetcher" 0 } },
        @{ id = 67; name = "Disable Boot Defrag"; action = { Set-RegVal "HKLM:\SOFTWARE\Microsoft\Dfrg\BootOptimizeFunction" "Enable" "N" "String" } },
        @{ id = 68; name = "Reduce Shadow Copy"; action = { $shadow = Get-WmiObject Win32_ShadowCopy -EA 0; $shadow | ForEach-Object { $_.Delete() } } },
        @{ id = 69; name = "Disable Hibernation"; action = { powercfg /hibernate off 2>$null | Out-Null } },
        @{ id = 70; name = "Increase Disk Cache"; action = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "CcPfThreshold" 0 } },
        @{ id = 71; name = "Optimize NTFS"; action = { fsutil repair initiate C: 2>$null | Out-Null } },
        @{ id = 72; name = "Disable USB Selective Suspend"; action = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Services\usbhub\Parameters" "EnableSelectiveSuspend" 0 } },
        @{ id = 73; name = "Disable Compression"; action = { compact /u /s:C:\ /i /q 2>$null | Out-Null } },
        @{ id = 74; name = "Clear System Cache"; action = { Remove-Item -Path "C:\Windows\Prefetch\*" -Force -EA 0 | Out-Null } },
        @{ id = 75; name = "Optimize MFT"; action = { defrag C: /U /V 2>$null | Out-Null } },
        @{ id = 76; name = "Disable File Access Log"; action = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" "EnableSecuritySignature" 0 } },
        @{ id = 77; name = "Set Low Power USB"; action = { powercfg /change usb-selective-suspend-timeout 0 2>$null | Out-Null } },
        @{ id = 78; name = "Disable Fast Startup"; action = { powercfg /h off 2>$null | Out-Null } },
        @{ id = 79; name = "Optimize SSD"; action = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Services\storahci\Parameters\Device0" "DisableInternalBkps" 1 } },
        @{ id = 80; name = "Clean Event Logs"; action = { Get-EventLog -List | ForEach-Object { Clear-EventLog -LogName $_.Log -EA 0 } } }
    );
    
    "User Experience" = @(
        @{ id = 81; name = "Disable Transparency"; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme" 0 } },
        @{ id = 82; name = "Dark Mode"; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme" 0; Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "SystemUsesLightTheme" 0 } },
        @{ id = 83; name = "Disable Notification Sounds"; action = { Set-RegVal "HKCU:\Control Panel\Sound" "Beep" "No" "String" } },
        @{ id = 84; name = "Disable Lock Screen"; action = { Set-RegVal "HKCU:\Software\Policies\Microsoft\Windows\Personalization" "NoLockScreen" 1 } },
        @{ id = 85; name = "Disable Sticky Keys"; action = { Set-RegVal "HKCU:\Control Panel\Accessibility\StickyKeys" "Flags" "506" "String" } },
        @{ id = 86; name = "Disable Filter Keys"; action = { Set-RegVal "HKCU:\Control Panel\Accessibility\Keyboard Response" "Flags" "122" "String" } },
        @{ id = 87; name = "Disable Toggle Keys"; action = { Set-RegVal "HKCU:\Control Panel\Accessibility\ToggleKeys" "Flags" "58" "String" } },
        @{ id = 88; name = "Disable Mouse Cursor Shadow"; action = { Set-RegVal "HKCU:\Control Panel\Cursors" "CursorShadow" "0" "String" } },
        @{ id = 89; name = "Hide Recently Used Files"; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" "ShowRecent" 0 } },
        @{ id = 90; name = "Disable Shortcut Arrows"; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons" "29" "%SystemRoot%\System32\shell32.dll,50" "String" } },
        @{ id = 91; name = "Hide Frequent Files"; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" "ShowFrequent" 0 } },
        @{ id = 92; name = "Disable Peek Preview"; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\DWM" "DisableFullWindowDrag" 1 } },
        @{ id = 93; name = "Disable Aero Snap"; action = { Set-RegVal "HKCU:\Control Panel\Desktop" "WindowArrangementStyle" "Cascade" "String" } },
        @{ id = 94; name = "Disable Start Menu Suggestions"; action = { Set-RegVal "HKCU:\Software\Policies\Microsoft\Windows\Explorer" "DisableSearchBoxSuggestions" 1 } },
        @{ id = 95; name = "Disable File Explorer Preview"; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowPreviewHandlers" 0 } },
        @{ id = 96; name = "Hide Recycle Bin Icon"; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowRecycleBinFullNotification" 0 } },
        @{ id = 97; name = "Disable Folder Animation"; action = { Set-RegVal "HKCU:\Control Panel\Desktop" "DragFullWindows" "0" "String" } },
        @{ id = 98; name = "Disable Cursor Trails"; action = { Set-RegVal "HKCU:\Control Panel\Mouse" "MouseTrails" "0" "String" } },
        @{ id = 99; name = "Disable Active Window Tracking"; action = { Set-RegVal "HKCU:\Control Panel\Mouse" "ActiveWindowTracking" "0" "String" } },
        @{ id = 100; name = "Optimize for Performance"; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 2 } }
    );
}

# Build GUI
$form = New-Object System.Windows.Forms.Form
$form.Text = "Anki's Windows Toolbox - 100 Gaming Tweaks"
$form.Size = New-Object System.Drawing.Size(1000, 700)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$form.ForeColor = [System.Drawing.Color]::White

# Title Label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "⚡ ANKI'S WINDOWS TOOLBOX - 100 TWEAKS ⚡"
$titleLabel.Location = New-Object System.Drawing.Point(10, 10)
$titleLabel.Size = New-Object System.Drawing.Size(980, 30)
$titleLabel.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::Cyan
$titleLabel.TextAlign = "MiddleCenter"
$form.Controls.Add($titleLabel)

# Category Buttons
$categoryPanel = New-Object System.Windows.Forms.Panel
$categoryPanel.Location = New-Object System.Drawing.Point(10, 50)
$categoryPanel.Size = New-Object System.Drawing.Size(980, 80)
$categoryPanel.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
$form.Controls.Add($categoryPanel)

$y = 10
foreach ($cat in $Categories.Keys) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $cat
    $btn.Location = New-Object System.Drawing.Point(10, $y)
    $btn.Size = New-Object System.Drawing.Size(220, 30)
    $btn.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 180)
    $btn.ForeColor = [System.Drawing.Color]::White
    $btn.Font = New-Object System.Drawing.Font("Arial", 9, [System.Drawing.FontStyle]::Bold)
    $btn.Add_Click({
        $script:CurrentCategory = $this.Text
        Update-TweakList
    })
    $categoryPanel.Controls.Add($btn)
    $y += 35
}

# Tweaks ListBox
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10, 140)
$listBox.Size = New-Object System.Drawing.Size(980, 400)
$listBox.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
$listBox.ForeColor = [System.Drawing.Color]::White
$listBox.Font = New-Object System.Drawing.Font("Courier New", 10)
$listBox.SelectionMode = "MultiSimple"
$form.Controls.Add($listBox)

# Button Panel
$buttonPanel = New-Object System.Windows.Forms.Panel
$buttonPanel.Location = New-Object System.Drawing.Point(10, 550)
$buttonPanel.Size = New-Object System.Drawing.Size(980, 110)
$buttonPanel.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
$form.Controls.Add($buttonPanel)

# Apply Button
$applyBtn = New-Object System.Windows.Forms.Button
$applyBtn.Text = "✓ APPLY SELECTED"
$applyBtn.Location = New-Object System.Drawing.Point(10, 10)
$applyBtn.Size = New-Object System.Drawing.Size(200, 40)
$applyBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 180, 0)
$applyBtn.ForeColor = [System.Drawing.Color]::White
$applyBtn.Font = New-Object System.Drawing.Font("Arial", 11, [System.Drawing.FontStyle]::Bold)
$applyBtn.Add_Click({
    foreach ($idx in $listBox.SelectedIndices) {
        $tweak = $listBox.Items[$idx]
        $id = [int]($tweak -split ':')[0].Trim()
        
        foreach ($cat in $Categories.Values) {
            $found = $cat | Where-Object { $_.id -eq $id }
            if ($found) {
                Write-Host "Applying: $($found.name)" -ForegroundColor Green
                & $found.action
                break
            }
        }
    }
    [System.Windows.Forms.MessageBox]::Show("Tweaks Applied! Restart for full effect.", "Success", "OK", "Information")
})
$buttonPanel.Controls.Add($applyBtn)

# Apply All Button
$applyAllBtn = New-Object System.Windows.Forms.Button
$applyAllBtn.Text = "★ APPLY ALL 100"
$applyAllBtn.Location = New-Object System.Drawing.Point(220, 10)
$applyAllBtn.Size = New-Object System.Drawing.Size(200, 40)
$applyAllBtn.BackColor = [System.Drawing.Color]::FromArgb(255, 100, 0)
$applyAllBtn.ForeColor = [System.Drawing.Color]::White
$applyAllBtn.Font = New-Object System.Drawing.Font("Arial", 11, [System.Drawing.FontStyle]::Bold)
$applyAllBtn.Add_Click({
    $result = [System.Windows.Forms.MessageBox]::Show("Apply ALL 100 tweaks? This cannot be undone!", "Confirm", "YesNo", "Warning")
    if ($result -eq "Yes") {
        foreach ($cat in $Categories.Values) {
            foreach ($tweak in $cat) {
                Write-Host "Applying: $($tweak.name)" -ForegroundColor Green
                & $tweak.action
            }
        }
        [System.Windows.Forms.MessageBox]::Show("All 100 tweaks applied! Restart now for full effect.", "Complete", "OK", "Information")
    }
})
$buttonPanel.Controls.Add($applyAllBtn)

# Restore Point Button
$restoreBtn = New-Object System.Windows.Forms.Button
$restoreBtn.Text = "📋 RESTORE POINT"
$restoreBtn.Location = New-Object System.Drawing.Point(430, 10)
$restoreBtn.Size = New-Object System.Drawing.Size(200, 40)
$restoreBtn.BackColor = [System.Drawing.Color]::FromArgb(180, 100, 0)
$restoreBtn.ForeColor = [System.Drawing.Color]::White
$restoreBtn.Font = New-Object System.Drawing.Font("Arial", 11, [System.Drawing.FontStyle]::Bold)
$restoreBtn.Add_Click({
    Write-Host "Creating restore point..." -ForegroundColor Yellow
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -EA 0
        Checkpoint-Computer -Description "AnkiToolbox-Backup" -RestorePointType "MODIFY_SETTINGS" -EA 0
        [System.Windows.Forms.MessageBox]::Show("Restore point created!", "Success", "OK", "Information")
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to create restore point.", "Error", "OK", "Error")
    }
})
$buttonPanel.Controls.Add($restoreBtn)

# Restart Button
$restartBtn = New-Object System.Windows.Forms.Button
$restartBtn.Text = "🔄 RESTART PC"
$restartBtn.Location = New-Object System.Drawing.Point(640, 10)
$restartBtn.Size = New-Object System.Drawing.Size(200, 40)
$restartBtn.BackColor = [System.Drawing.Color]::FromArgb(200, 0, 0)
$restartBtn.ForeColor = [System.Drawing.Color]::White
$restartBtn.Font = New-Object System.Drawing.Font("Arial", 11, [System.Drawing.FontStyle]::Bold)
$restartBtn.Add_Click({
    $result = [System.Windows.Forms.MessageBox]::Show("Restart computer now?", "Confirm", "YesNo", "Question")
    if ($result -eq "Yes") {
        Restart-Computer -Force
    }
})
$buttonPanel.Controls.Add($restartBtn)

# Status Label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Select a category and tweaks to apply"
$statusLabel.Location = New-Object System.Drawing.Point(10, 60)
$statusLabel.Size = New-Object System.Drawing.Size(960, 20)
$statusLabel.Font = New-Object System.Drawing.Font("Arial", 9)
$statusLabel.ForeColor = [System.Drawing.Color]::Yellow
$buttonPanel.Controls.Add($statusLabel)

# Update Tweaks List Function
function Update-TweakList {
    $listBox.Items.Clear()
    if ($Categories.ContainsKey($script:CurrentCategory)) {
        foreach ($tweak in $Categories[$script:CurrentCategory]) {
            $listBox.Items.Add("$($tweak.id): $($tweak.name)")
        }
        $statusLabel.Text = "Category: $($script:CurrentCategory) - $(($Categories[$script:CurrentCategory]).Count) tweaks"
    }
}

# Initialize with first category
$script:CurrentCategory = $Categories.Keys[0]
Update-TweakList

$form.ShowDialog()
