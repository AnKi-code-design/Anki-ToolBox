#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Anki's Windows Toolbox - FPS Boost / Low Latency / Network Optimization
.DESCRIPTION
    Menu-driven PowerShell toolbox for gaming performance.
    Use: irm https://raw.githubusercontent.com/AnKi-code-design/Anki-ToolBox/main/AnkiToolbox.ps1 | iex
.NOTES
    - Creates a System Restore point before applying tweaks (recommended: don't skip it)
    - Every tweak function is independent and can be toggled/reverted individually
#>

# Clear any previous errors
$Error.Clear()
$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

# Check if running as admin - if not, relaunch
function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Write-Host "Relaunching as Administrator..." -ForegroundColor Yellow
    $scriptPath = $MyInvocation.MyCommand.Path
    if (-not $scriptPath) {
        $scriptPath = $PSCommandPath
    }
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/AnKi-code-design/Anki-ToolBox/main/AnkiToolbox.ps1 | iex`""
    exit
}

$Host.UI.RawUI.WindowTitle = "Anki's Toolbox"

# ============================================================
#  UTILITIES
# ============================================================

function Write-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔═══════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║            ANKI'S WINDOWS TOOLBOX              ║" -ForegroundColor Cyan
    Write-Host "  ║       FPS Boost / Low Ping / Low Delay         ║" -ForegroundColor Cyan
    Write-Host "  ╚═══════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Pause-Return {
    Write-Host ""
    Write-Host "Press any key to return to menu..." -ForegroundColor DarkGray
    try {
        $null = $Host.UI.RawUI.ReadKey("NoRepeat,IncludeKeyDown")
    } catch {
        Read-Host "Press Enter to continue"
    }
}

function Set-Reg {
    param($Path, $Name, $Value, $Type = "DWord")
    try {
        if (-not (Test-Path $Path)) { 
            New-Item -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null 
        }
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force -ErrorAction SilentlyContinue | Out-Null
    } catch {
        Write-Host "[!] Error setting registry: $_" -ForegroundColor Red
    }
}

# ============================================================
#  FPS / SYSTEM PERFORMANCE TWEAKS
# ============================================================

function Invoke-GameDVROff {
    Write-Host "[*] Disabling Xbox Game Bar / Game DVR..." -ForegroundColor Yellow
    Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0
    Set-Reg "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" 0
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 0
    Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode" 2
    Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode" 1
    Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_DXGIHonorFSEWindowsCompatible" 1
    Write-Host "[+] Game DVR disabled." -ForegroundColor Green
    Pause-Return
}

function Invoke-GameModeOn {
    Write-Host "[*] Enabling Windows Game Mode + Hardware GPU Scheduling..." -ForegroundColor Yellow
    Set-Reg "HKCU:\Software\Microsoft\GameBar" "AllowAutoGameMode" 1
    Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2
    Write-Host "[+] Game Mode + HAGS enabled. (Restart required for HAGS)" -ForegroundColor Green
    Pause-Return
}

function Invoke-PowerPlanUltimate {
    Write-Host "[*] Applying Ultimate Performance power plan..." -ForegroundColor Yellow
    $guid = "e9a42b02-d5df-448d-aa00-03f14749eb61"
    powercfg -duplicatescheme $guid 2>$null | Out-Null
    $plan = powercfg /list 2>$null | Select-String "Ultimate Performance"
    if ($plan) {
        $activeGuid = ($plan.ToString() -split '\s+')[3]
        powercfg /setactive $activeGuid 2>$null
        powercfg /change monitor-timeout-ac 0 2>$null
        powercfg /change standby-timeout-ac 0 2>$null
        Write-Host "[+] Ultimate Performance plan active." -ForegroundColor Green
    } else {
        Write-Host "[!] Could not create plan, falling back to High Performance." -ForegroundColor Red
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
    }
    Pause-Return
}

function Invoke-VisualEffectsPerformance {
    Write-Host "[*] Setting visual effects to 'Best Performance'..." -ForegroundColor Yellow
    Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 2
    Set-Reg "HKCU:\Control Panel\Desktop" "DragFullWindows" "0" "String"
    Set-Reg "HKCU:\Control Panel\Desktop" "MenuShowDelay" "0" "String"
    Set-Reg "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "0" "String"
    Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations" 0
    Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ListviewAlphaSelect" 0
    Set-Reg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ListviewShadow" 0
    Set-Reg "HKCU:\Control Panel\Desktop" "UserPreferencesMask" ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) "Binary"
    Write-Host "[+] Visual effects minimized for performance." -ForegroundColor Green
    Pause-Return
}

function Invoke-MMCSS-GamesPriority {
    Write-Host "[*] Tuning MMCSS 'Games' task priority..." -ForegroundColor Yellow
    $path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
    Set-Reg $path "GPU Priority" 8
    Set-Reg $path "Priority" 6
    Set-Reg $path "Scheduling Category" "High" "String"
    Set-Reg $path "SFIO Priority" "High" "String"
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 0
    Write-Host "[+] Games given priority CPU/GPU scheduling." -ForegroundColor Green
    Pause-Return
}

function Invoke-DisableFullscreenOptimizations {
    Write-Host "[*] Disabling Fullscreen Optimizations..." -ForegroundColor Yellow
    Set-Reg "HKCU:\System\GameConfigStore" "GameDVR_FSEBehavior" 2
    Write-Host "[+] Done." -ForegroundColor Green
    Pause-Return
}

function Invoke-DisableTelemetryServices {
    Write-Host "[*] Disabling telemetry/indexing services..." -ForegroundColor Yellow
    $services = @("DiagTrack","dmwappushservice","WSearch","SysMain")
    foreach ($svc in $services) {
        try {
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
            Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Host "    -> $svc disabled" -ForegroundColor DarkGray
        } catch {}
    }
    Write-Host "[+] Services disabled." -ForegroundColor Green
    Pause-Return
}

function Invoke-PageFileOptimize {
    Write-Host "[*] Setting Page File to System Managed..." -ForegroundColor Yellow
    try {
        $cs = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges -ErrorAction SilentlyContinue
        if ($cs) {
            $cs.AutomaticManagedPagefile = $true
            $cs.Put() | Out-Null
            Write-Host "[+] Page file set to auto-managed." -ForegroundColor Green
        }
    } catch {
        Write-Host "[!] Could not set page file." -ForegroundColor Red
    }
    Pause-Return
}

# ============================================================
#  NETWORK / PING / LATENCY TWEAKS
# ============================================================

function Invoke-DisableNagle {
    Write-Host "[*] Disabling Nagle's Algorithm..." -ForegroundColor Yellow
    $ifRoot = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
    try {
        Get-ChildItem $ifRoot -ErrorAction SilentlyContinue | ForEach-Object {
            Set-Reg $_.PSPath "TcpAckFrequency" 1
            Set-Reg $_.PSPath "TCPNoDelay" 1
        }
    } catch {}
    Write-Host "[+] Nagle's Algorithm disabled." -ForegroundColor Green
    Pause-Return
}

function Invoke-NetworkThrottlingOff {
    Write-Host "[*] Disabling Network Throttling Index..." -ForegroundColor Yellow
    Set-Reg "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 0xffffffff
    Write-Host "[+] Network throttling removed." -ForegroundColor Green
    Pause-Return
}

function Invoke-TcpOptimize {
    Write-Host "[*] Applying TCP stack tweaks..." -ForegroundColor Yellow
    netsh int tcp set global autotuninglevel=normal 2>$null | Out-Null
    netsh int tcp set global chimney=disabled 2>$null | Out-Null
    netsh int tcp set global rss=enabled 2>$null | Out-Null
    netsh int tcp set global ecncapability=disabled 2>$null | Out-Null
    netsh int tcp set heuristics disabled 2>$null | Out-Null
    netsh int tcp set supplemental Internet congestionprovider=ctcp 2>$null | Out-Null
    Write-Host "[+] TCP stack optimized." -ForegroundColor Green
    Pause-Return
}

function Invoke-DnsFastPublic {
    Write-Host "[*] Setting DNS to Cloudflare/Google..." -ForegroundColor Yellow
    try {
        $adapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" }
        foreach ($a in $adapters) {
            Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses ("1.1.1.1","8.8.8.8") -ErrorAction SilentlyContinue
            Write-Host "    -> $($a.Name) updated" -ForegroundColor DarkGray
        }
        ipconfig /flushdns 2>$null | Out-Null
    } catch {}
    Write-Host "[+] DNS updated." -ForegroundColor Green
    Pause-Return
}

function Invoke-DisableQoSReservation {
    Write-Host "[*] Removing QoS bandwidth reservation..." -ForegroundColor Yellow
    Set-Reg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" "NonBestEffortLimit" 0
    Write-Host "[+] QoS reservation set to 0%." -ForegroundColor Green
    Pause-Return
}

function Invoke-DisableIPv6 {
    Write-Host "[*] Disabling IPv6..." -ForegroundColor Yellow
    try {
        Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
            Disable-NetAdapterBinding -InterfaceAlias $_.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
        }
    } catch {}
    Write-Host "[+] IPv6 disabled." -ForegroundColor Green
    Pause-Return
}

function Invoke-DisablePowerSavingNIC {
    Write-Host "[*] Disabling NIC power saving..." -ForegroundColor Yellow
    try {
        Get-NetAdapter -ErrorAction SilentlyContinue | ForEach-Object {
            Disable-NetAdapterPowerManagement -Name $_.Name -ErrorAction SilentlyContinue
            Write-Host "    -> $($_.Name) power saving disabled" -ForegroundColor DarkGray
        }
    } catch {}
    Write-Host "[+] NIC power management disabled." -ForegroundColor Green
    Pause-Return
}

function Invoke-CreateRestorePoint {
    Write-Host "[*] Creating System Restore Point..." -ForegroundColor Yellow
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "AnkiToolbox-PreTweak" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
        Write-Host "[+] Restore point created." -ForegroundColor Green
    } catch {
        Write-Host "[!] Restore point creation failed (may be disabled by policy)." -ForegroundColor Red
    }
    Pause-Return
}

# ============================================================
#  APPLY ALL (SAFE BUNDLE)
# ============================================================

function Invoke-ApplyAllSafe {
    Write-Host "[*] Applying ALL tweaks... This may take a moment..." -ForegroundColor Cyan
    Write-Host ""
    Invoke-GameDVROff
    Invoke-GameModeOn
    Invoke-PowerPlanUltimate
    Invoke-VisualEffectsPerformance
    Invoke-MMCSS-GamesPriority
    Invoke-DisableFullscreenOptimizations
    Invoke-DisableTelemetryServices
    Invoke-DisableNagle
    Invoke-NetworkThrottlingOff
    Invoke-TcpOptimize
    Invoke-DisableQoSReservation
    Invoke-DisablePowerSavingNIC
    Write-Host ""
    Write-Host "[+] ALL TWEAKS APPLIED. Restart your PC for full effect." -ForegroundColor Green
    Write-Host ""
    Pause-Return
}

# ============================================================
#  MAIN MENU LOOP
# ============================================================

function Show-Menu {
    Write-Banner
    Write-Host "  --- SETUP ---" -ForegroundColor DarkCyan
    Write-Host "   0. Create System Restore Point (do this first!)"
    Write-Host ""
    Write-Host "  --- FPS / PERFORMANCE ---" -ForegroundColor DarkCyan
    Write-Host "   1. Disable Game DVR / Xbox Game Bar"
    Write-Host "   2. Enable Game Mode + Hardware GPU Scheduling"
    Write-Host "   3. Set Ultimate Performance power plan"
    Write-Host "   4. Visual effects -> Best Performance"
    Write-Host "   5. MMCSS 'Games' priority tuning"
    Write-Host "   6. Disable Fullscreen Optimizations"
    Write-Host "   7. Disable telemetry/indexing services"
    Write-Host "   8. Page file -> system managed"
    Write-Host ""
    Write-Host "  --- LOW PING / LOW DELAY ---" -ForegroundColor DarkCyan
    Write-Host "   9. Disable Nagle's Algorithm"
    Write-Host "  10. Disable Network Throttling"
    Write-Host "  11. TCP stack optimize"
    Write-Host "  12. Set fast public DNS"
    Write-Host "  13. Remove QoS bandwidth reservation"
    Write-Host "  14. Disable IPv6"
    Write-Host "  15. Disable NIC power saving"
    Write-Host ""
    Write-Host "  --- BUNDLE ---" -ForegroundColor DarkCyan
    Write-Host "  99. APPLY ALL SAFE TWEAKS" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "   R. Restart computer"
    Write-Host "   Q. Quit"
    Write-Host ""
}

# Main loop
do {
    Show-Menu
    $choice = Read-Host "  Select option"
    Write-Host ""
    
    switch ($choice) {
        "0"  { Invoke-CreateRestorePoint }
        "1"  { Invoke-GameDVROff }
        "2"  { Invoke-GameModeOn }
        "3"  { Invoke-PowerPlanUltimate }
        "4"  { Invoke-VisualEffectsPerformance }
        "5"  { Invoke-MMCSS-GamesPriority }
        "6"  { Invoke-DisableFullscreenOptimizations }
        "7"  { Invoke-DisableTelemetryServices }
        "8"  { Invoke-PageFileOptimize }
        "9"  { Invoke-DisableNagle }
        "10" { Invoke-NetworkThrottlingOff }
        "11" { Invoke-TcpOptimize }
        "12" { Invoke-DnsFastPublic }
        "13" { Invoke-DisableQoSReservation }
        "14" { Invoke-DisableIPv6 }
        "15" { Invoke-DisablePowerSavingNIC }
        "99" { Invoke-ApplyAllSafe }
        "R"  { 
            Write-Host "Restarting computer..." -ForegroundColor Yellow
            Start-Sleep 2
            Restart-Computer -Force
        }
        "r"  { 
            Write-Host "Restarting computer..." -ForegroundColor Yellow
            Start-Sleep 2
            Restart-Computer -Force
        }
        "Q"  { exit }
        "q"  { exit }
        default { 
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
            Start-Sleep 1
        }
    }
} while ($true)
