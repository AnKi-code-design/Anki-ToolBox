#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Anki's Windows Toolbox - FPS Boost / Low Latency / Network Optimization
.DESCRIPTION
    Fast menu-driven PowerShell toolbox for gaming performance.
#>

$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

# Quick admin check
function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/AnKi-code-design/Anki-ToolBox/main/AnkiToolbox.ps1 | iex`""
    exit
}

$Host.UI.RawUI.WindowTitle = "Anki's Toolbox"

# ============================================================
#  UTILITIES
# ============================================================

function Write-Banner {
    Clear-Host
    Write-Host "  ╔═══════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║            ANKI'S WINDOWS TOOLBOX              ║" -ForegroundColor Cyan
    Write-Host "  ║       FPS Boost / Low Ping / Low Delay         ║" -ForegroundColor Cyan
    Write-Host "  ╚═══════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Pause-Return {
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor DarkGray
    try { $null = $Host.UI.RawUI.ReadKey("NoRepeat,IncludeKeyDown") } catch { Read-Host "" }
}

function Set-Reg {
    param($Path, $Name, $Value, $Type = "DWord")
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force -EA SilentlyContinue | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force -EA SilentlyContinue | Out-Null
}

# ============================================================
#  FPS / SYSTEM PERFORMANCE TWEAKS
# ============================================================

function Invoke-GameDVROff {
    Write-Host "[*] Disabling Game DVR..." -ForegroundColor Yellow
    Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0
    Set-Reg "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" 0
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 0
    Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode" 2
    Write-Host "[+] Done." -ForegroundColor Green
    Pause-Return
}

function Invoke-GameModeOn {
    Write-Host "[*] Enabling Game Mode + GPU Scheduling..." -ForegroundColor Yellow
    Set-Reg "HKCU:\Software\Microsoft\GameBar" "AllowAutoGameMode" 1
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2
    Write-Host "[+] Done. (Restart needed for HAGS)" -ForegroundColor Green
    Pause-Return
}

function Invoke-PowerPlanUltimate {
    Write-Host "[*] Setting Ultimate Performance..." -ForegroundColor Yellow
    $guid = "e9a42b02-d5df-448d-aa00-03f14749eb61"
    powercfg -duplicatescheme $guid 2>$null | Out-Null
    $plan = powercfg /list 2>$null | Select-String "Ultimate Performance"
    if ($plan) {
        $activeGuid = ($plan.ToString() -split '\s+')[3]
        powercfg /setactive $activeGuid 2>$null
        powercfg /change monitor-timeout-ac 0 2>$null
        Write-Host "[+] Done." -ForegroundColor Green
    } else {
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
        Write-Host "[+] High Performance set." -ForegroundColor Green
    }
    Pause-Return
}

function Invoke-VisualEffectsOff {
    Write-Host "[*] Disabling visual effects..." -ForegroundColor Yellow
    Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 2
    Set-Reg "HKCU:\Control Panel\Desktop" "DragFullWindows" "0" "String"
    Set-Reg "HKCU:\Control Panel\Desktop" "MenuShowDelay" "0" "String"
    Set-Reg "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "0" "String"
    Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations" 0
    Write-Host "[+] Done." -ForegroundColor Green
    Pause-Return
}

function Invoke-MMCSS {
    Write-Host "[*] Tuning MMCSS priority..." -ForegroundColor Yellow
    $path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
    Set-Reg $path "Priority" 6
    Set-Reg $path "GPU Priority" 8
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 0
    Write-Host "[+] Done." -ForegroundColor Green
    Pause-Return
}

function Invoke-DisableFSOptimizations {
    Write-Host "[*] Disabling fullscreen optimizations..." -ForegroundColor Yellow
    Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_FSEBehavior" 2
    Write-Host "[+] Done." -ForegroundColor Green
    Pause-Return
}

function Invoke-DisableTelemetry {
    Write-Host "[*] Disabling telemetry services..." -ForegroundColor Yellow
    $services = @("DiagTrack","dmwappushservice","WSearch","SysMain")
    foreach ($svc in $services) {
        Stop-Service -Name $svc -Force -EA SilentlyContinue
        Set-Service -Name $svc -StartupType Disabled -EA SilentlyContinue
    }
    Write-Host "[+] Done." -ForegroundColor Green
    Pause-Return
}

function Invoke-PageFileOptimize {
    Write-Host "[*] Setting page file to auto-managed..." -ForegroundColor Yellow
    try {
        $cs = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges -EA SilentlyContinue
        if ($cs) { $cs.AutomaticManagedPagefile = $true; $cs.Put() | Out-Null }
    } catch {}
    Write-Host "[+] Done." -ForegroundColor Green
    Pause-Return
}

function Invoke-DisableAnimations {
    Write-Host "[*] Disabling all animations..." -ForegroundColor Yellow
    Set-Reg "HKCU:\Control Panel\Desktop" "UserPreferencesMask" ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) "Binary"
    Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ListviewAlphaSelect" 0
    Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ListviewShadow" 0
    Write-Host "[+] Done." -ForegroundColor Green
    Pause-Return
}

function Invoke-DisableCortana {
    Write-Host "[*] Disabling Cortana..." -ForegroundColor Yellow
    Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "CortanaConsent" 0
    Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 0
    Write-Host "[+] Done." -ForegroundColor Green
    Pause-Return
}

function Invoke-DisableXboxFeatures {
    Write-Host "[*] Disabling Xbox features..." -ForegroundColor Yellow
    Set-Reg "HKCU:\Software\Microsoft\XboxGameOverlay" "GameOverlayEnabled" 0
    Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0
    Write-Host "[+] Done." -ForegroundColor Green
    Pause-Return
}

# ============================================================
#  NETWORK / PING / LATENCY TWEAKS
# ============================================================

function Invoke-DisableNagle {
    Write-Host "[*] Disabling Nagle's Algorithm..." -ForegroundColor Yellow
    $ifRoot = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
    Get-ChildItem $ifRoot -EA SilentlyContinue | ForEach-Object {
        Set-Reg $_.PSPath "TcpAckFrequency" 1
        Set-Reg $_.PSPath "TCPNoDelay" 1
    }
    Write-Host "[+] Done." -ForegroundColor Green
    Pause-Return
}

function Invoke-NetworkThrottlingOff {
    Write-Host "[*] Disabling network throttling..." -ForegroundColor Yellow
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 0xffffffff
    Write-Host "[+] Done." -ForegroundColor Green
    Pause-Return
}

function Invoke-TcpOptimize {
    Write-Host "[*] Optimizing TCP stack..." -ForegroundColor Yellow
    netsh int tcp set global autotuninglevel=normal 2>$null | Out-Null
    netsh int tcp set global chimney=disabled 2>$null | Out-Null
    netsh int tcp set global rss=enabled 2>$null | Out-Null
    netsh int tcp set global ecncapability=disabled 2>$null | Out-Null
    Write-Host "[+] Done." -ForegroundColor Green
    Pause-Return
}

function Invoke-DnsFast {
    Write-Host "[*] Setting fast DNS (1.1.1.1 / 8.8.8.8)..." -ForegroundColor Yellow
    try {
        Get-NetAdapter -EA SilentlyContinue | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
            Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses ("1.1.1.1","8.8.8.8") -EA SilentlyContinue
        }
        ipconfig /flushdns 2>$null | Out-Null
    } catch {}
    Write-Host "[+] Done." -ForegroundColor Green
    Pause-Return
}

function Invoke-DisableQoS {
    Write-Host "[*] Disabling QoS reservation..." -ForegroundColor Yellow
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" "NonBestEffortLimit" 0
    Write-Host "[+] Done." -ForegroundColor Green
    Pause-Return
}

function Invoke-DisableIPv6 {
    Write-Host "[*] Disabling IPv6..." -ForegroundColor Yellow
    Get-NetAdapter -EA SilentlyContinue | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
        Disable-NetAdapterBinding -InterfaceAlias $_.Name -ComponentID ms_tcpip6 -EA SilentlyContinue
    }
    Write-Host "[+] Done." -ForegroundColor Green
    Pause-Return
}

function Invoke-NICPowerSave {
    Write-Host "[*] Disabling NIC power saving..." -ForegroundColor Yellow
    Get-NetAdapter -EA SilentlyContinue | ForEach-Object {
        Disable-NetAdapterPowerManagement -Name $_.Name -EA SilentlyContinue
    }
    Write-Host "[+] Done." -ForegroundColor Green
    Pause-Return
}

function Invoke-LANOptimize {
    Write-Host "[*] Optimizing LAN settings..." -ForegroundColor Yellow
    netsh int tcp set global fastopen=enabled 2>$null | Out-Null
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpMaxDataRetransmissions" 3
    Write-Host "[+] Done." -ForegroundColor Green
    Pause-Return
}

function Invoke-DisableWindowsUpdate {
    Write-Host "[*] Pausing Windows Update..." -ForegroundColor Yellow
    try {
        Stop-Service -Name wuauserv -Force -EA SilentlyContinue
        Set-Service -Name wuauserv -StartupType Disabled -EA SilentlyContinue
    } catch {}
    Write-Host "[+] Done." -ForegroundColor Green
    Pause-Return
}

function Invoke-CleanTemp {
    Write-Host "[*] Cleaning temp files..." -ForegroundColor Yellow
    Remove-Item -Path "$env:temp\*" -Recurse -Force -EA SilentlyContinue | Out-Null
    Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -EA SilentlyContinue | Out-Null
    Write-Host "[+] Done." -ForegroundColor Green
    Pause-Return
}

function Invoke-RestorePoint {
    Write-Host "[*] Creating System Restore Point..." -ForegroundColor Yellow
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -EA SilentlyContinue
        Checkpoint-Computer -Description "AnkiToolbox" -RestorePointType "MODIFY_SETTINGS" -EA SilentlyContinue
        Write-Host "[+] Restore point created." -ForegroundColor Green
    } catch {
        Write-Host "[!] Restore point creation failed." -ForegroundColor Red
    }
    Pause-Return
}

# ============================================================
#  APPLY ALL
# ============================================================

function Invoke-ApplyAll {
    Write-Host "[*] Applying ALL tweaks..." -ForegroundColor Cyan
    Invoke-GameDVROff; Invoke-GameModeOn; Invoke-PowerPlanUltimate; Invoke-VisualEffectsOff
    Invoke-MMCSS; Invoke-DisableFSOptimizations; Invoke-DisableTelemetry; Invoke-PageFileOptimize
    Invoke-DisableAnimations; Invoke-DisableCortana; Invoke-DisableXboxFeatures
    Invoke-DisableNagle; Invoke-NetworkThrottlingOff; Invoke-TcpOptimize; Invoke-DnsFast
    Invoke-DisableQoS; Invoke-DisableIPv6; Invoke-NICPowerSave; Invoke-LANOptimize
    Invoke-CleanTemp
    Write-Host "[+] ALL TWEAKS APPLIED! Restart PC for full effect." -ForegroundColor Green
    Pause-Return
}

# ============================================================
#  MAIN MENU
# ============================================================

function Show-Menu {
    Write-Banner
    Write-Host "  --- SETUP ---" -ForegroundColor DarkCyan
    Write-Host "   0. Create System Restore Point"
    Write-Host ""
    Write-Host "  --- FPS / PERFORMANCE ---" -ForegroundColor DarkCyan
    Write-Host "   1. Disable Game DVR"
    Write-Host "   2. Enable Game Mode + GPU Scheduling"
    Write-Host "   3. Ultimate Performance Power Plan"
    Write-Host "   4. Disable Visual Effects"
    Write-Host "   5. Tune MMCSS Priority"
    Write-Host "   6. Disable Fullscreen Optimizations"
    Write-Host "   7. Disable Telemetry Services"
    Write-Host "   8. Auto Manage Page File"
    Write-Host "   9. Disable Animations"
    Write-Host "  10. Disable Cortana"
    Write-Host "  11. Disable Xbox Features"
    Write-Host ""
    Write-Host "  --- NETWORK / PING ---" -ForegroundColor DarkCyan
    Write-Host "  12. Disable Nagle's Algorithm"
    Write-Host "  13. Disable Network Throttling"
    Write-Host "  14. Optimize TCP Stack"
    Write-Host "  15. Set Fast DNS"
    Write-Host "  16. Disable QoS Reservation"
    Write-Host "  17. Disable IPv6"
    Write-Host "  18. Disable NIC Power Saving"
    Write-Host "  19. LAN Optimization"
    Write-Host "  20. Clean Temp Files"
    Write-Host "  21. Disable Windows Update"
    Write-Host ""
    Write-Host "  --- BUNDLE ---" -ForegroundColor DarkCyan
    Write-Host "  99. APPLY ALL TWEAKS" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "   R. Restart Computer"
    Write-Host "   Q. Quit"
    Write-Host ""
}

do {
    Show-Menu
    $choice = Read-Host "  Select option"
    Write-Host ""
    
    switch ($choice) {
        "0"  { Invoke-RestorePoint }
        "1"  { Invoke-GameDVROff }
        "2"  { Invoke-GameModeOn }
        "3"  { Invoke-PowerPlanUltimate }
        "4"  { Invoke-VisualEffectsOff }
        "5"  { Invoke-MMCSS }
        "6"  { Invoke-DisableFSOptimizations }
        "7"  { Invoke-DisableTelemetry }
        "8"  { Invoke-PageFileOptimize }
        "9"  { Invoke-DisableAnimations }
        "10" { Invoke-DisableCortana }
        "11" { Invoke-DisableXboxFeatures }
        "12" { Invoke-DisableNagle }
        "13" { Invoke-NetworkThrottlingOff }
        "14" { Invoke-TcpOptimize }
        "15" { Invoke-DnsFast }
        "16" { Invoke-DisableQoS }
        "17" { Invoke-DisableIPv6 }
        "18" { Invoke-NICPowerSave }
        "19" { Invoke-LANOptimize }
        "20" { Invoke-CleanTemp }
        "21" { Invoke-DisableWindowsUpdate }
        "99" { Invoke-ApplyAll }
        "R"  { Restart-Computer -Force }
        "r"  { Restart-Computer -Force }
        "Q"  { exit }
        "q"  { exit }
        default { Write-Host "Invalid choice." -ForegroundColor Red; Start-Sleep 1 }
    }
} while ($true)
