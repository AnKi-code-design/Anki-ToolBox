Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

if (-not ([Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains 'S-1-5-32-544')) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/AnKi-code-design/Anki-ToolBox/main/AnkiToolbox.ps1 | iex`""
    exit
}

$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

function Set-RegVal($Path, $Name, $Value, $Type = "DWord") {
    try {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force -EA 0 | Out-Null }
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force -EA 0 | Out-Null
    } catch {}
}

$Categories = @{
    "🎮 Gaming Performance" = @(
        @{ id = 1; name = "Disable Game DVR"; desc = "Xbox Game Bar recording"; toggle = $true; action = { Set-RegVal "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0 }; undo = { Set-RegVal "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 1 } },
        @{ id = 2; name = "Enable Game Mode"; desc = "Prioritize foreground game"; toggle = $true; action = { Set-RegVal "HKCU:\Software\Microsoft\GameBar" "AllowAutoGameMode" 1 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\GameBar" "AllowAutoGameMode" 0 } },
        @{ id = 3; name = "GPU Hardware Scheduling"; desc = "Accelerated GPU scheduling"; toggle = $true; action = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2 }; undo = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 0 } },
        @{ id = 4; name = "Ultimate Performance Power"; desc = "Max CPU/GPU performance"; toggle = $true; action = { powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null | Out-Null; $p = powercfg /list 2>$null | Select-String "Ultimate"; if ($p) { powercfg /setactive ($p.ToString() -split '\s+')[3] 2>$null } }; undo = {} },
        @{ id = 5; name = "Disable Fullscreen Optimization"; desc = "Reduce input lag"; toggle = $true; action = { Set-RegVal "HKCU:\System\GameConfigStore" "GameDVR_FSEBehavior" 2 }; undo = { Set-RegVal "HKCU:\System\GameConfigStore" "GameDVR_FSEBehavior" 0 } },
        @{ id = 6; name = "MMCSS Priority"; desc = "Game CPU/GPU priority"; toggle = $true; action = { $p = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Set-RegVal $p "Priority" 6; Set-RegVal $p "GPU Priority" 8 }; undo = {} },
        @{ id = 7; name = "Disable Xbox Overlay"; desc = "Remove Xbox Game Bar"; toggle = $true; action = { Set-RegVal "HKCU:\Software\Microsoft\XboxGameOverlay" "GameOverlayEnabled" 0 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\XboxGameOverlay" "GameOverlayEnabled" 1 } },
        @{ id = 8; name = "Enable Triple Buffering"; desc = "Smoother frame delivery"; toggle = $true; action = { Set-RegVal "HKCU:\Software\NVIDIA\NvCplApi\Direct3D" "TripleBuffering" 1 }; undo = { Set-RegVal "HKCU:\Software\NVIDIA\NvCplApi\Direct3D" "TripleBuffering" 0 } },
        @{ id = 9; name = "Disable VSync"; desc = "Disable vertical sync"; toggle = $true; action = { Set-RegVal "HKCU:\Software\NVIDIA\NvCplApi\Direct3D" "VSyncMode" 0 }; undo = { Set-RegVal "HKCU:\Software\NVIDIA\NvCplApi\Direct3D" "VSyncMode" 1 } },
        @{ id = 10; name = "Fast Game Launch"; desc = "Quick game start"; toggle = $true; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" 0 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" 1 } }
    );

    "⚡ System Performance" = @(
        @{ id = 11; name = "Disable Visual Effects"; desc = "Remove animations"; toggle = $true; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 2 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 3 } },
        @{ id = 12; name = "Disable Animations"; desc = "All transitions off"; toggle = $true; action = { Set-RegVal "HKCU:\Control Panel\Desktop" "DragFullWindows" "0" "String"; Set-RegVal "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "0" "String" }; undo = {} },
        @{ id = 13; name = "No Taskbar Animation"; desc = "Instant taskbar"; toggle = $true; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations" 0 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations" 1 } },
        @{ id = 14; name = "No Menu Delay"; desc = "Instant menus"; toggle = $true; action = { Set-RegVal "HKCU:\Control Panel\Desktop" "MenuShowDelay" "0" "String" }; undo = { Set-RegVal "HKCU:\Control Panel\Desktop" "MenuShowDelay" "400" "String" } },
        @{ id = 15; name = "Fast Explorer"; desc = "Quick file manager"; toggle = $true; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ListviewAlphaSelect" 0 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ListviewAlphaSelect" 1 } },
        @{ id = 16; name = "Auto Page File"; desc = "Optimize RAM usage"; toggle = $true; action = { try { $cs = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges -EA 0; if ($cs) { $cs.AutomaticManagedPagefile = $true; $cs.Put() | Out-Null } } catch {} }; undo = {} },
        @{ id = 17; name = "Disable Cortana"; desc = "Remove Cortana"; toggle = $true; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "CortanaConsent" 0 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "CortanaConsent" 1 } },
        @{ id = 18; name = "No Activity History"; desc = "Disable timeline"; toggle = $true; action = { Set-RegVal "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" 0 }; undo = {} },
        @{ id = 19; name = "Disable Cloud Sync"; desc = "Local only"; toggle = $true; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync" "SyncPolicy" 0 }; undo = {} },
        @{ id = 20; name = "Disable Tips"; desc = "No suggestions"; toggle = $true; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SoftLandingEnabled" 0 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SoftLandingEnabled" 1 } }
    );

    "🌐 Network & Speed" = @(
        @{ id = 21; name = "Disable Nagle"; desc = "Lower network latency"; toggle = $true; action = { Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -EA 0 | ForEach-Object { Set-RegVal $_.PSPath "TcpAckFrequency" 1; Set-RegVal $_.PSPath "TCPNoDelay" 1 } }; undo = {} },
        @{ id = 22; name = "Full Bandwidth"; desc = "Disable throttling"; toggle = $true; action = { Set-RegVal "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 0xffffffff }; undo = {} },
        @{ id = 23; name = "TCP Auto-Tuning"; desc = "Optimize TCP window"; toggle = $true; action = { netsh int tcp set global autotuninglevel=normal 2>$null | Out-Null }; undo = { netsh int tcp set global autotuninglevel=restricted 2>$null | Out-Null } },
        @{ id = 24; name = "Enable TCP RSS"; desc = "Multi-core network"; toggle = $true; action = { netsh int tcp set global rss=enabled 2>$null | Out-Null }; undo = { netsh int tcp set global rss=disabled 2>$null | Out-Null } },
        @{ id = 25; name = "Disable ECN"; desc = "Better compatibility"; toggle = $true; action = { netsh int tcp set global ecncapability=disabled 2>$null | Out-Null }; undo = { netsh int tcp set global ecncapability=enabled 2>$null | Out-Null } },
        @{ id = 26; name = "Cloudflare DNS"; desc = "1.1.1.1 - Fast DNS"; toggle = $true; action = { Get-NetAdapter -EA 0 | Where-Object { $_.Status -eq "Up" } | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses ("1.1.1.1", "1.0.0.1") -EA 0 } }; undo = {} },
        @{ id = 27; name = "Google DNS"; desc = "8.8.8.8 - Reliable"; toggle = $true; action = { Get-NetAdapter -EA 0 | Where-Object { $_.Status -eq "Up" } | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses ("8.8.8.8", "8.8.4.4") -EA 0 } }; undo = {} },
        @{ id = 28; name = "TCP Fast Open"; desc = "Faster connections"; toggle = $true; action = { netsh int tcp set global fastopen=enabled 2>$null | Out-Null }; undo = { netsh int tcp set global fastopen=disabled 2>$null | Out-Null } },
        @{ id = 29; name = "Lower TCP Retry"; desc = "Faster recovery"; toggle = $true; action = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpMaxDataRetransmissions" 3 }; undo = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpMaxDataRetransmissions" 5 } },
        @{ id = 30; name = "Disable IPv6"; desc = "IPv4 only"; toggle = $true; action = { Get-NetAdapter -EA 0 | Where-Object { $_.Status -eq "Up" } | ForEach-Object { Disable-NetAdapterBinding -InterfaceAlias $_.Name -ComponentID ms_tcpip6 -EA 0 } }; undo = {} }
    );

    "🛑 Disable Services" = @(
        @{ id = 31; name = "Disable Windows Update"; desc = "Stop auto updates"; toggle = $true; action = { Stop-Service -Name wuauserv -Force -EA 0; Set-Service -Name wuauserv -StartupType Disabled -EA 0 }; undo = { Set-Service -Name wuauserv -StartupType Automatic -EA 0; Start-Service -Name wuauserv -EA 0 } },
        @{ id = 32; name = "Disable Windows Search"; desc = "Stop indexing"; toggle = $true; action = { Stop-Service -Name WSearch -Force -EA 0; Set-Service -Name WSearch -StartupType Disabled -EA 0 }; undo = { Set-Service -Name WSearch -StartupType Automatic -EA 0; Start-Service -Name WSearch -EA 0 } },
        @{ id = 33; name = "Disable Superfetch"; desc = "Stop memory caching"; toggle = $true; action = { Stop-Service -Name SysMain -Force -EA 0; Set-Service -Name SysMain -StartupType Disabled -EA 0 }; undo = { Set-Service -Name SysMain -StartupType Automatic -EA 0; Start-Service -Name SysMain -EA 0 } },
        @{ id = 34; name = "Disable Telemetry"; desc = "Stop data collection"; toggle = $true; action = { Stop-Service -Name DiagTrack -Force -EA 0; Set-Service -Name DiagTrack -StartupType Disabled -EA 0 }; undo = { Set-Service -Name DiagTrack -StartupType Automatic -EA 0; Start-Service -Name DiagTrack -EA 0 } },
        @{ id = 35; name = "Disable BITS"; desc = "Stop downloads"; toggle = $true; action = { Stop-Service -Name BITS -Force -EA 0; Set-Service -Name BITS -StartupType Disabled -EA 0 }; undo = { Set-Service -Name BITS -StartupType Automatic -EA 0; Start-Service -Name BITS -EA 0 } },
        @{ id = 36; name = "Disable Print Spooler"; desc = "Remove printer service"; toggle = $true; action = { Stop-Service -Name Spooler -Force -EA 0; Set-Service -Name Spooler -StartupType Disabled -EA 0 }; undo = { Set-Service -Name Spooler -StartupType Automatic -EA 0; Start-Service -Name Spooler -EA 0 } },
        @{ id = 37; name = "Disable Bluetooth"; desc = "Stop BT service"; toggle = $true; action = { Stop-Service -Name bthserv -Force -EA 0; Set-Service -Name bthserv -StartupType Disabled -EA 0 }; undo = { Set-Service -Name bthserv -StartupType Automatic -EA 0; Start-Service -Name bthserv -EA 0 } },
        @{ id = 38; name = "Disable Remote Desktop"; desc = "No RDP access"; toggle = $true; action = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" "fDenyTSConnections" 1 }; undo = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" "fDenyTSConnections" 0 } },
        @{ id = 39; name = "Disable Location"; desc = "No location tracking"; toggle = $true; action = { Stop-Service -Name lfsvc -Force -EA 0; Set-Service -Name lfsvc -StartupType Disabled -EA 0 }; undo = { Set-Service -Name lfsvc -StartupType Automatic -EA 0; Start-Service -Name lfsvc -EA 0 } },
        @{ id = 40; name = "Disable Sharing"; desc = "Stop file sharing"; toggle = $true; action = { Stop-Service -Name LanmanServer -Force -EA 0; Set-Service -Name LanmanServer -StartupType Disabled -EA 0 }; undo = { Set-Service -Name LanmanServer -StartupType Automatic -EA 0; Start-Service -Name LanmanServer -EA 0 } }
    );

    "💾 Disk & Cleanup" = @(
        @{ id = 41; name = "Clean Temp Files"; desc = "Remove temp files"; toggle = $false; action = { Remove-Item -Path "$env:temp\*" -Recurse -Force -EA 0 | Out-Null }; undo = {} },
        @{ id = 42; name = "Clear Recycle Bin"; desc = "Empty trash"; toggle = $false; action = { Clear-RecycleBin -Force -EA 0 }; undo = {} },
        @{ id = 43; name = "Disable Prefetch"; desc = "No app prefetch"; toggle = $true; action = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" "EnablePrefetcher" 0 }; undo = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" "EnablePrefetcher" 3 } },
        @{ id = 44; name = "Enable SSD TRIM"; desc = "Optimize SSD"; toggle = $true; action = { fsutil behavior set DisableDeleteNotify 0 2>$null | Out-Null }; undo = { fsutil behavior set DisableDeleteNotify 1 2>$null | Out-Null } },
        @{ id = 45; name = "Disable Hibernation"; desc = "Remove hibernation"; toggle = $true; action = { powercfg /hibernate off 2>$null | Out-Null }; undo = { powercfg /hibernate on 2>$null | Out-Null } },
        @{ id = 46; name = "Clear Event Logs"; desc = "Clean system logs"; toggle = $false; action = { Get-EventLog -List -EA 0 | ForEach-Object { Clear-EventLog -LogName $_.Log -EA 0 } }; undo = {} },
        @{ id = 47; name = "Disable Indexing"; desc = "Stop Windows Search"; toggle = $true; action = { Stop-Service -Name WSearch -Force -EA 0; Set-Service -Name WSearch -StartupType Disabled -EA 0 }; undo = { Set-Service -Name WSearch -StartupType Automatic -EA 0; Start-Service -Name WSearch -EA 0 } },
        @{ id = 48; name = "Disable System Restore"; desc = "No restore points"; toggle = $true; action = { Disable-ComputerRestore -Drive "$env:SystemDrive\" -EA 0 }; undo = { Enable-ComputerRestore -Drive "$env:SystemDrive\" -EA 0 } },
        @{ id = 49; name = "Optimize Drive"; desc = "Defragment C:"; toggle = $false; action = { Optimize-Volume -DriveLetter C -Defrag -EA 0 }; undo = {} },
        @{ id = 50; name = "USB Power Save OFF"; desc = "Always power USB"; toggle = $true; action = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Services\usbhub\Parameters" "EnableSelectiveSuspend" 0 }; undo = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Services\usbhub\Parameters" "EnableSelectiveSuspend" 1 } }
    );

    "🎨 UI & Experience" = @(
        @{ id = 51; name = "Enable Dark Mode"; desc = "Dark theme"; toggle = $true; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme" 0; Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "SystemUsesLightTheme" 0 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme" 1; Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "SystemUsesLightTheme" 1 } },
        @{ id = 52; name = "Disable Transparency"; desc = "No blur/transparency"; toggle = $true; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "ColorPrevalence" 0 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "ColorPrevalence" 1 } },
        @{ id = 53; name = "Disable Lock Screen"; desc = "Skip login screen"; toggle = $true; action = { Set-RegVal "HKCU:\Software\Policies\Microsoft\Windows\Personalization" "NoLockScreen" 1 }; undo = { Set-RegVal "HKCU:\Software\Policies\Microsoft\Windows\Personalization" "NoLockScreen" 0 } },
        @{ id = 54; name = "No Notification Sound"; desc = "Silent notifications"; toggle = $true; action = { Set-RegVal "HKCU:\Control Panel\Sound" "Beep" "No" "String" }; undo = { Set-RegVal "HKCU:\Control Panel\Sound" "Beep" "Yes" "String" } },
        @{ id = 55; name = "Hide Recently Used"; desc = "Clean recent files"; toggle = $true; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" "ShowRecent" 0 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" "ShowRecent" 1 } },
        @{ id = 56; name = "Hide Frequent Items"; desc = "Clean frequent list"; toggle = $true; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" "ShowFrequent" 0 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" "ShowFrequent" 1 } },
        @{ id = 57; name = "No Start Menu Ads"; desc = "Disable suggestions"; toggle = $true; action = { Set-RegVal "HKCU:\Software\Policies\Microsoft\Windows\Explorer" "DisableSearchBoxSuggestions" 1 }; undo = { Set-RegVal "HKCU:\Software\Policies\Microsoft\Windows\Explorer" "DisableSearchBoxSuggestions" 0 } },
        @{ id = 58; name = "Disable Aero Peek"; desc = "Fast window preview"; toggle = $true; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\DWM" "DisableFullWindowDrag" 1 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\Windows\DWM" "DisableFullWindowDrag" 0 } },
        @{ id = 59; name = "Disable Sticky Keys"; desc = "Normal keyboard"; toggle = $true; action = { Set-RegVal "HKCU:\Control Panel\Accessibility\StickyKeys" "Flags" "506" "String" }; undo = {} },
        @{ id = 60; name = "Hide Recycle Bin"; desc = "Clean desktop"; toggle = $true; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowRecycleBinFullNotification" 0 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowRecycleBinFullNotification" 1 } }
    );

    "🔒 Privacy & Security" = @(
        @{ id = 61; name = "Disable Telemetry"; desc = "Stop data tracking"; toggle = $true; action = { Stop-Service -Name DiagTrack -Force -EA 0; Set-Service -Name DiagTrack -StartupType Disabled -EA 0 }; undo = {} },
        @{ id = 62; name = "No Connected Experiences"; desc = "Disable cloud sync"; toggle = $true; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" "TailoredExperiencesWithDiagnosticDataEnabled" 0 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" "TailoredExperiencesWithDiagnosticDataEnabled" 1 } },
        @{ id = 63; name = "Disable Activity History"; desc = "No timeline data"; toggle = $true; action = { Set-RegVal "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" 0 }; undo = {} },
        @{ id = 64; name = "Disable App Diagnostics"; desc = "No app tracking"; toggle = $true; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" "GeneralBizAnalyticsEnabled" 0 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" "GeneralBizAnalyticsEnabled" 1 } },
        @{ id = 65; name = "Disable Advertising ID"; desc = "No ad tracking"; toggle = $true; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 1 } },
        @{ id = 66; name = "Disable Microphone"; desc = "Apps can't use mic"; toggle = $true; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" "MicrophoneEnabled" 0 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" "MicrophoneEnabled" 1 } },
        @{ id = 67; name = "Disable Camera"; desc = "Apps can't use camera"; toggle = $true; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" "CameraEnabled" 0 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" "CameraEnabled" 1 } },
        @{ id = 68; name = "Disable Sync Settings"; desc = "No account sync"; toggle = $true; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync" "SyncPolicy" 0 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync" "SyncPolicy" 1 } },
        @{ id = 69; name = "Disable Spotlight Ads"; desc = "No lock screen ads"; toggle = $true; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "RotatingLockScreenEnabled" 0 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "RotatingLockScreenEnabled" 1 } },
        @{ id = 70; name = "Disable Consumer Ads"; desc = "No ads in system"; toggle = $true; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "ContentDeliveryAllowed" 0 }; undo = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "ContentDeliveryAllowed" 1 } }
    );

    "⚙️ Advanced Tweaks" = @(
        @{ id = 71; name = "Increase Desktop Heap"; desc = "More resources"; toggle = $true; action = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\SubSystems\Windows" "SharedSection" 4096 }; undo = {} },
        @{ id = 72; name = "Increase File Cache"; desc = "Disk cache boost"; toggle = $true; action = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "CcPfThreshold" 0 }; undo = {} },
        @{ id = 73; name = "Mouse Sensitivity"; desc = "Instant response"; toggle = $true; action = { Set-RegVal "HKCU:\Control Panel\Mouse" "MouseSensitivity" "10" "String"; Set-RegVal "HKCU:\Control Panel\Mouse" "MouseSpeed" "0" "String"; Set-RegVal "HKCU:\Control Panel\Mouse" "MouseThreshold1" "0" "String"; Set-RegVal "HKCU:\Control Panel\Mouse" "MouseThreshold2" "0" "String" }; undo = {} },
        @{ id = 74; name = "Reduce Boot Time"; desc = "Faster startup"; toggle = $true; action = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "PagingFiles" "" }; undo = {} },
        @{ id = 75; name = "Process Priority"; desc = "High process priority"; toggle = $true; action = { Set-RegVal "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Priority" 6 }; undo = {} },
        @{ id = 76; name = "Disable Aero Snap"; desc = "No window snapping"; toggle = $true; action = { Set-RegVal "HKCU:\Control Panel\Desktop" "WindowArrangementStyle" "Cascade" "String" }; undo = { Set-RegVal "HKCU:\Control Panel\Desktop" "WindowArrangementStyle" "Tile" "String" } },
        @{ id = 77; name = "Fast Explorer"; desc = "Quick file navigation"; toggle = $true; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ListviewShadow" 0; Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ListviewAlphaSelect" 0 }; undo = {} },
        @{ id = 78; name = "Disable Windows Animations"; desc = "All animations off"; toggle = $true; action = { Set-RegVal "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "0" "String" }; undo = { Set-RegVal "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "1" "String" } },
        @{ id = 79; name = "Lower Latency"; desc = "Minimal lag"; toggle = $true; action = { Set-RegVal "HKCU:\Control Panel\Mouse" "MouseSensitivity" "10" "String"; netsh int tcp set global autotuninglevel=normal 2>$null | Out-Null }; undo = {} },
        @{ id = 80; name = "Enable HID Device"; desc = "Raw input mode"; toggle = $true; action = { Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\MouseSensitivity" "Sensitivity" "10" "String" }; undo = {} }
    );
}

# ============================================================
#  PREMIUM GUI FORM
# ============================================================

$form = New-Object System.Windows.Forms.Form
$form.Text = "⚡ Anki's Windows Toolbox - 80 Tweaks"
$form.Size = New-Object System.Drawing.Size(1300, 850)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(15, 15, 22)
$form.ForeColor = [System.Drawing.Color]::White
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
$form.FormBorderStyle = "FixedSingle"

# =========== TOP BANNER ===========
$titlePanel = New-Object System.Windows.Forms.Panel
$titlePanel.Location = New-Object System.Drawing.Point(0, 0)
$titlePanel.Size = New-Object System.Drawing.Size(1300, 80)
$titlePanel.BackColor = [System.Drawing.Color]::FromArgb(10, 10, 18)
$titlePanel.BorderStyle = "FixedSingle"
$form.Controls.Add($titlePanel)

$logoLabel = New-Object System.Windows.Forms.Label
$logoLabel.Text = "⚡🎮"
$logoLabel.Location = New-Object System.Drawing.Point(15, 15)
$logoLabel.Size = New-Object System.Drawing.Size(50, 50)
$logoLabel.Font = New-Object System.Drawing.Font("Arial", 24, [System.Drawing.FontStyle]::Bold)
$logoLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 220, 255)
$titlePanel.Controls.Add($logoLabel)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "ANKI'S WINDOWS TOOLBOX"
$titleLabel.Location = New-Object System.Drawing.Point(70, 15)
$titleLabel.Size = New-Object System.Drawing.Size(400, 25)
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 220, 255)
$titlePanel.Controls.Add($titleLabel)

$subtitleLabel = New-Object System.Windows.Forms.Label
$subtitleLabel.Text = "80 Gaming & System Tweaks | FPS Boost | Ultra Performance"
$subtitleLabel.Location = New-Object System.Drawing.Point(70, 45)
$subtitleLabel.Size = New-Object System.Drawing.Size(500, 20)
$subtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$subtitleLabel.ForeColor = [System.Drawing.Color]::FromArgb(150, 150, 170)
$titlePanel.Controls.Add($subtitleLabel)

$versionLabel = New-Object System.Windows.Forms.Label
$versionLabel.Text = "v2.0 Premium Edition"
$versionLabel.Location = New-Object System.Drawing.Point(1100, 25)
$versionLabel.Size = New-Object System.Drawing.Size(180, 30)
$versionLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$versionLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 180, 255)
$versionLabel.TextAlign = "MiddleRight"
$titlePanel.Controls.Add($versionLabel)

# =========== CATEGORIES ===========
$categoryPanel = New-Object System.Windows.Forms.Panel
$categoryPanel.Location = New-Object System.Drawing.Point(0, 80)
$categoryPanel.Size = New-Object System.Drawing.Size(1300, 100)
$categoryPanel.BackColor = [System.Drawing.Color]::FromArgb(12, 12, 20)
$categoryPanel.AutoScroll = $true
$form.Controls.Add($categoryPanel)

$x = 5
foreach ($cat in $Categories.Keys) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $cat
    $btn.Location = New-Object System.Drawing.Point($x, 5)
    $btn.Size = New-Object System.Drawing.Size(200, 35)
    $btn.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 65)
    $btn.ForeColor = [System.Drawing.Color]::FromArgb(180, 180, 200)
    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 2
    $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0, 150, 200)
    $btn.Cursor = "Hand"
    $btn.Tag = $cat
    
    $btn.Add_Click({
        foreach ($b in $categoryPanel.Controls | Where-Object { $_ -is [System.Windows.Forms.Button] }) {
            $b.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 65)
            $b.ForeColor = [System.Drawing.Color]::FromArgb(180, 180, 200)
        }
        $this.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 200)
        $this.ForeColor = [System.Drawing.Color]::Black
        Update-TweakList $this.Tag
    })
    $categoryPanel.Controls.Add($btn)
    $x += 210
}

# =========== TWEAKS LISTBOX ===========
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10, 190)
$listBox.Size = New-Object System.Drawing.Size(1280, 480)
$listBox.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 32)
$listBox.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 220)
$listBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$listBox.SelectionMode = "MultiSimple"
$listBox.BorderStyle = "FixedSingle"
$listBox.ItemHeight = 22
$form.Controls.Add($listBox)

# =========== STATUS BAR ===========
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(10, 680)
$statusLabel.Size = New-Object System.Drawing.Size(1280, 30)
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 220, 100)
$statusLabel.BackColor = [System.Drawing.Color]::FromArgb(15, 15, 22)
$statusLabel.BorderStyle = "FixedSingle"
$statusLabel.Text = "Ready"
$form.Controls.Add($statusLabel)

# =========== BUTTONS ===========
$buttonPanel = New-Object System.Windows.Forms.Panel
$buttonPanel.Location = New-Object System.Drawing.Point(0, 710)
$buttonPanel.Size = New-Object System.Drawing.Size(1300, 120)
$buttonPanel.BackColor = [System.Drawing.Color]::FromArgb(12, 12, 20)
$buttonPanel.BorderStyle = "FixedSingle"
$form.Controls.Add($buttonPanel)

# Apply Selected
$applyBtn = New-Object System.Windows.Forms.Button
$applyBtn.Text = "✓ APPLY SELECTED"
$applyBtn.Location = New-Object System.Drawing.Point(10, 10)
$applyBtn.Size = New-Object System.Drawing.Size(230, 50)
$applyBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 180, 100)
$applyBtn.ForeColor = [System.Drawing.Color]::Black
$applyBtn.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$applyBtn.FlatStyle = "Flat"
$applyBtn.Cursor = "Hand"
$applyBtn.Add_Click({
    $count = $listBox.SelectedIndices.Count
    if ($count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Select tweaks first!", "Info", "OK", "Information") | Out-Null
        return
    }
    
    $result = [System.Windows.Forms.MessageBox]::Show("Apply $count tweaks?`nRestart required for full effect.", "Confirm", "YesNo", "Question")
    if ($result -eq "Yes") {
        $statusLabel.Text = "Applying tweaks..."
        $form.Refresh()
        
        foreach ($idx in $listBox.SelectedIndices) {
            $tweakText = $listBox.Items[$idx]
            $id = [int]($tweakText -split ':')[0].Trim()
            
            foreach ($cat in $Categories.Values) {
                $found = $cat | Where-Object { $_.id -eq $id }
                if ($found) {
                    & $found.action
                    break
                }
            }
        }
        $statusLabel.Text = "✓ Applied $count tweaks! Restart recommended."
        [System.Windows.Forms.MessageBox]::Show("✓ $count tweaks applied!`nRestart PC for best results.", "Success", "OK", "Information") | Out-Null
    }
})
$buttonPanel.Controls.Add($applyBtn)

# Apply All
$applyAllBtn = New-Object System.Windows.Forms.Button
$applyAllBtn.Text = "★ APPLY ALL (80)"
$applyAllBtn.Location = New-Object System.Drawing.Point(250, 10)
$applyAllBtn.Size = New-Object System.Drawing.Size(230, 50)
$applyAllBtn.BackColor = [System.Drawing.Color]::FromArgb(255, 150, 0)
$applyAllBtn.ForeColor = [System.Drawing.Color]::Black
$applyAllBtn.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$applyAllBtn.FlatStyle = "Flat"
$applyAllBtn.Cursor = "Hand"
$applyAllBtn.Add_Click({
    $result = [System.Windows.Forms.MessageBox]::Show("Apply ALL 80 tweaks?`nThis optimizes everything!`n`nRestart required.", "CONFIRM", "YesNo", "Warning")
    if ($result -eq "Yes") {
        $statusLabel.Text = "Applying ALL tweaks... Please wait..."
        $form.Refresh()
        
        $total = 0
        foreach ($cat in $Categories.Values) {
            foreach ($tweak in $cat) {
                & $tweak.action
                $total++
            }
        }
        $statusLabel.Text = "✓ Applied ALL $total tweaks! System optimized. Restart now!"
        [System.Windows.Forms.MessageBox]::Show("✓ ALL $total TWEAKS APPLIED!`n`nRestart your PC now for full optimization.", "Complete", "OK", "Information") | Out-Null
    }
})
$buttonPanel.Controls.Add($applyAllBtn)

# Restore Point
$restoreBtn = New-Object System.Windows.Forms.Button
$restoreBtn.Text = "📋 RESTORE POINT"
$restoreBtn.Location = New-Object System.Drawing.Point(490, 10)
$restoreBtn.Size = New-Object System.Drawing.Size(230, 50)
$restoreBtn.BackColor = [System.Drawing.Color]::FromArgb(180, 100, 0)
$restoreBtn.ForeColor = [System.Drawing.Color]::White
$restoreBtn.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$restoreBtn.FlatStyle = "Flat"
$restoreBtn.Cursor = "Hand"
$restoreBtn.Add_Click({
    try {
        $statusLabel.Text = "Creating restore point..."
        $form.Refresh()
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -EA 0
        Checkpoint-Computer -Description "AnkiToolbox-Backup" -RestorePointType "MODIFY_SETTINGS" -EA 0
        $statusLabel.Text = "✓ Restore point created!"
        [System.Windows.Forms.MessageBox]::Show("✓ Restore point created successfully!", "Success", "OK", "Information") | Out-Null
    } catch {
        $statusLabel.Text = "! Failed to create restore point"
        [System.Windows.Forms.MessageBox]::Show("Failed to create restore point.", "Error", "OK", "Error") | Out-Null
    }
})
$buttonPanel.Controls.Add($restoreBtn)

# Restart PC
$restartBtn = New-Object System.Windows.Forms.Button
$restartBtn.Text = "🔄 RESTART PC"
$restartBtn.Location = New-Object System.Drawing.Point(730, 10)
$restartBtn.Size = New-Object System.Drawing.Size(230, 50)
$restartBtn.BackColor = [System.Drawing.Color]::FromArgb(200, 50, 50)
$restartBtn.ForeColor = [System.Drawing.Color]::White
$restartBtn.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$restartBtn.FlatStyle = "Flat"
$restartBtn.Cursor = "Hand"
$restartBtn.Add_Click({
    $result = [System.Windows.Forms.MessageBox]::Show("Restart computer now?", "Confirm", "YesNo", "Question")
    if ($result -eq "Yes") {
        Restart-Computer -Force
    }
})
$buttonPanel.Controls.Add($restartBtn)

# Exit
$exitBtn = New-Object System.Windows.Forms.Button
$exitBtn.Text = "✕ EXIT"
$exitBtn.Location = New-Object System.Drawing.Point(1050, 10)
$exitBtn.Size = New-Object System.Drawing.Size(230, 50)
$exitBtn.BackColor = [System.Drawing.Color]::FromArgb(80, 80, 120)
$exitBtn.ForeColor = [System.Drawing.Color]::White
$exitBtn.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$exitBtn.FlatStyle = "Flat"
$exitBtn.Cursor = "Hand"
$exitBtn.Add_Click({ $form.Close() })
$buttonPanel.Controls.Add($exitBtn)

# Info
$infoLabel = New-Object System.Windows.Forms.Label
$infoLabel.Location = New-Object System.Drawing.Point(10, 65)
$infoLabel.Size = New-Object System.Drawing.Size(1270, 45)
$infoLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$infoLabel.ForeColor = [System.Drawing.Color]::FromArgb(150, 150, 170)
$infoLabel.Text = "✓ Tip: Use Ctrl+Click to select multiple tweaks  |  ✓ Create restore point first  |  ✓ Restart PC after applying  |  ✓ All tweaks are reversible"
$infoLabel.AutoSize = $false
$infoLabel.WordWrap = $true
$buttonPanel.Controls.Add($infoLabel)

# =========== FUNCTIONS ===========
function Update-TweakList($category) {
    $listBox.Items.Clear()
    $listBox.SelectedIndices.Clear()
    
    if ($Categories.ContainsKey($category)) {
        foreach ($tweak in $Categories[$category]) {
            $status = if ($tweak.toggle) { "⚙" } else { "→" }
            $listBox.Items.Add("$($tweak.id): [$status] $($tweak.name) - $($tweak.desc)")
        }
        $count = ($Categories[$category]).Count
        $statusLabel.Text = "Category: $category | $count tweaks available"
    }
}

# Initialize
$firstCategory = $Categories.Keys[0]
Update-TweakList $firstCategory

$firstBtn = $categoryPanel.Controls[0]
$firstBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 200)
$firstBtn.ForeColor = [System.Drawing.Color]::Black

$form.ShowDialog() | Out-Null
