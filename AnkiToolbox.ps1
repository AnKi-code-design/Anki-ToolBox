#Requires -RunAsAdministrator
$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

if (-not ([Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains 'S-1-5-32-544')) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/AnKi-code-design/Anki-ToolBox/main/AnkiToolbox.ps1 | iex`""
    exit
}

Clear-Host
$Host.UI.RawUI.WindowTitle = "Anki's Toolbox"

function Menu {
    Write-Host "  ╔═══════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║            ANKI'S WINDOWS TOOLBOX              ║" -ForegroundColor Cyan
    Write-Host "  ║       FPS Boost / Low Ping / Low Delay         ║" -ForegroundColor Cyan
    Write-Host "  ╚═══════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  0. Create Restore Point   | 1. Game DVR Off" -ForegroundColor DarkCyan
    Write-Host "  2. Game Mode On           | 3. Ultimate Power Plan" -ForegroundColor DarkCyan
    Write-Host "  4. No Visual Effects      | 5. MMCSS Priority" -ForegroundColor DarkCyan
    Write-Host "  6. FS Optimizations       | 7. Kill Telemetry" -ForegroundColor DarkCyan
    Write-Host "  8. Page File Auto         | 9. Kill Animations" -ForegroundColor DarkCyan
    Write-Host "  10. Kill Cortana          | 11. Kill Xbox" -ForegroundColor DarkCyan
    Write-Host "  12. Disable Nagle         | 13. Network Throttle" -ForegroundColor DarkCyan
    Write-Host "  14. TCP Optimize          | 15. Fast DNS" -ForegroundColor DarkCyan
    Write-Host "  16. Kill QoS              | 17. Disable IPv6" -ForegroundColor DarkCyan
    Write-Host "  18. NIC Power Save        | 19. LAN Optimize" -ForegroundColor DarkCyan
    Write-Host "  20. Clean Temp            | 21. Kill Updates" -ForegroundColor DarkCyan
    Write-Host "  99. APPLY ALL             | R. Restart  | Q. Quit" -ForegroundColor Magenta
    Write-Host ""
}

function S($p,$n,$v,$t="DWord"){if(-not(Test-Path $p)){New-Item -Path $p -Force -EA 0|Out-Null}New-ItemProperty -Path $p -Name $n -Value $v -PropertyType $t -Force -EA 0|Out-Null}
function T1{Write-Host "[*] Disabling Game DVR..." -ForegroundColor Yellow;S "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0;S "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" 0;S "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 0;Write-Host "[+] Done."-ForegroundColor Green}
function T2{Write-Host "[*] Game Mode + GPU..." -ForegroundColor Yellow;S "HKCU:\Software\Microsoft\GameBar" "AllowAutoGameMode" 1;S "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2;Write-Host "[+] Done."-ForegroundColor Green}
function T3{Write-Host "[*] Ultimate Power..." -ForegroundColor Yellow;powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null|Out-Null;$p=powercfg /list 2>$null|Select-String "Ultimate";if($p){powercfg /setactive ($p.ToString()-split'\s+')[3] 2>$null}else{powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null};Write-Host "[+] Done."-ForegroundColor Green}
function T4{Write-Host "[*] Visual Effects Off..." -ForegroundColor Yellow;S "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 2;S "HKCU:\Control Panel\Desktop" "DragFullWindows" "0" "String";S "HKCU:\Control Panel\Desktop" "MenuShowDelay" "0" "String";S "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "0" "String";S "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations" 0;Write-Host "[+] Done."-ForegroundColor Green}
function T5{Write-Host "[*] MMCSS Priority..." -ForegroundColor Yellow;$p="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games";S $p "Priority" 6;S $p "GPU Priority" 8;S "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 0;Write-Host "[+] Done."-ForegroundColor Green}
function T6{Write-Host "[*] FS Optimizations..." -ForegroundColor Yellow;S "HKCU:\System\GameConfigStore" "GameDVR_FSEBehavior" 2;Write-Host "[+] Done."-ForegroundColor Green}
function T7{Write-Host "[*] Killing Telemetry..." -ForegroundColor Yellow;@("DiagTrack","dmwappushservice","WSearch","SysMain")|ForEach-Object{Stop-Service -Name $_ -Force -EA 0;Set-Service -Name $_ -StartupType Disabled -EA 0};Write-Host "[+] Done."-ForegroundColor Green}
function T8{Write-Host "[*] Page File Auto..." -ForegroundColor Yellow;try{(Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges -EA 0).AutomaticManagedPagefile=$true;(Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges -EA 0).Put()|Out-Null}catch{};Write-Host "[+] Done."-ForegroundColor Green}
function T9{Write-Host "[*] Animations Off..." -ForegroundColor Yellow;S "HKCU:\Control Panel\Desktop" "UserPreferencesMask" ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) "Binary";S "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ListviewAlphaSelect" 0;S "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ListviewShadow" 0;Write-Host "[+] Done."-ForegroundColor Green}
function T10{Write-Host "[*] Cortana Off..." -ForegroundColor Yellow;S "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "CortanaConsent" 0;S "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 0;Write-Host "[+] Done."-ForegroundColor Green}
function T11{Write-Host "[*] Xbox Off..." -ForegroundColor Yellow;S "HKCU:\Software\Microsoft\XboxGameOverlay" "GameOverlayEnabled" 0;Write-Host "[+] Done."-ForegroundColor Green}
function T12{Write-Host "[*] Nagle Off..." -ForegroundColor Yellow;Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -EA 0|ForEach-Object{S $_.PSPath "TcpAckFrequency" 1;S $_.PSPath "TCPNoDelay" 1};Write-Host "[+] Done."-ForegroundColor Green}
function T13{Write-Host "[*] Network Throttle..." -ForegroundColor Yellow;S "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 0xffffffff;Write-Host "[+] Done."-ForegroundColor Green}
function T14{Write-Host "[*] TCP Optimize..." -ForegroundColor Yellow;netsh int tcp set global autotuninglevel=normal 2>$null|Out-Null;netsh int tcp set global chimney=disabled 2>$null|Out-Null;netsh int tcp set global rss=enabled 2>$null|Out-Null;netsh int tcp set global ecncapability=disabled 2>$null|Out-Null;Write-Host "[+] Done."-ForegroundColor Green}
function T15{Write-Host "[*] Fast DNS..." -ForegroundColor Yellow;Get-NetAdapter -EA 0|Where-Object{$_.Status -eq "Up"}|ForEach-Object{Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses ("1.1.1.1","8.8.8.8") -EA 0};ipconfig /flushdns 2>$null|Out-Null;Write-Host "[+] Done."-ForegroundColor Green}
function T16{Write-Host "[*] QoS Off..." -ForegroundColor Yellow;S "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" "NonBestEffortLimit" 0;Write-Host "[+] Done."-ForegroundColor Green}
function T17{Write-Host "[*] IPv6 Off..." -ForegroundColor Yellow;Get-NetAdapter -EA 0|Where-Object{$_.Status -eq "Up"}|ForEach-Object{Disable-NetAdapterBinding -InterfaceAlias $_.Name -ComponentID ms_tcpip6 -EA 0};Write-Host "[+] Done."-ForegroundColor Green}
function T18{Write-Host "[*] NIC Power Save..." -ForegroundColor Yellow;Get-NetAdapter -EA 0|ForEach-Object{Disable-NetAdapterPowerManagement -Name $_.Name -EA 0};Write-Host "[+] Done."-ForegroundColor Green}
function T19{Write-Host "[*] LAN Optimize..." -ForegroundColor Yellow;netsh int tcp set global fastopen=enabled 2>$null|Out-Null;S "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpMaxDataRetransmissions" 3;Write-Host "[+] Done."-ForegroundColor Green}
function T20{Write-Host "[*] Clean Temp..." -ForegroundColor Yellow;Remove-Item -Path "$env:temp\*" -Recurse -Force -EA 0|Out-Null;Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -EA 0|Out-Null;Write-Host "[+] Done."-ForegroundColor Green}
function T21{Write-Host "[*] Updates Off..." -ForegroundColor Yellow;Stop-Service -Name wuauserv -Force -EA 0;Set-Service -Name wuauserv -StartupType Disabled -EA 0;Write-Host "[+] Done."-ForegroundColor Green}
function T0{Write-Host "[*] Restore Point..." -ForegroundColor Yellow;try{Enable-ComputerRestore -Drive "$env:SystemDrive\" -EA 0;Checkpoint-Computer -Description "AnkiToolbox" -RestorePointType "MODIFY_SETTINGS" -EA 0;Write-Host "[+] Created."-ForegroundColor Green}catch{Write-Host "[!] Failed."-ForegroundColor Red}}
function TALL{Write-Host "[*] Applying ALL (21 tweaks)..." -ForegroundColor Cyan;T1;T2;T3;T4;T5;T6;T7;T8;T9;T10;T11;T12;T13;T14;T15;T16;T17;T18;T19;T20;T21;Write-Host "[+] ALL COMPLETE! Restart now."-ForegroundColor Green}

do{
    Clear-Host
    Menu
    $c=Read-Host "Select"
    switch($c){
        "0"{T0};"1"{T1};"2"{T2};"3"{T3};"4"{T4};"5"{T5};"6"{T6};"7"{T7};"8"{T8};"9"{T9}
        "10"{T10};"11"{T11};"12"{T12};"13"{T13};"14"{T14};"15"{T15};"16"{T16};"17"{T17};"18"{T18};"19"{T19};"20"{T20};"21"{T21}
        "99"{TALL}
        "R"{Restart-Computer -Force};"r"{Restart-Computer -Force}
        "Q"{exit};"q"{exit}
        default{Write-Host "Invalid."-ForegroundColor Red;Start-Sleep 1}
    }
}while($true)
