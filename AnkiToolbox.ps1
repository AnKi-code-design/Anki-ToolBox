<#
.SYNOPSIS
    Anki's Windows Toolbox - GUI tweak selector (FPS boost / low ping / low delay)
.DESCRIPTION
    Checkbox GUI. Pick tweaks per category, hit Apply. Launch remotely with:
    irm yoururl.com/win | iex
.NOTES
    Every tweak here is one I can explain the mechanism for. No padding.
    Risky/system-altering tweaks are included but UNCHECKED by default with warnings.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ---------------------------------------------------------------
#  Admin elevation
# ---------------------------------------------------------------
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/AnKi-code-design/Anki-ToolBox/main/AnkiToolbox.ps1 | iex`""
    exit
}

$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

# ---------------------------------------------------------------
#  Helpers
# ---------------------------------------------------------------
function Set-RegVal {
    param($Path, $Name, $Value, $Type = "DWord")
    try {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force -EA 0 | Out-Null }
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force -EA 0 | Out-Null
    } catch {}
}

function Disable-SvcSafe {
    param($Name)
    try {
        Stop-Service -Name $Name -Force -EA 0
        Set-Service -Name $Name -StartupType Disabled -EA 0
    } catch {}
}

# ---------------------------------------------------------------
#  Tweak catalog
#  Every "risky" = $true tweak is unchecked by default and carries a warning
#  shown in the description panel when selected.
# ---------------------------------------------------------------
$Categories = [ordered]@{

    "FPS & Rendering" = @(
        @{ name = "Disable Game DVR / Xbox Game Bar"; risky = $false
           desc = "Stops background screen-recording capture that runs even when you're not recording. Frees CPU/GPU headroom."
           action = {
               Set-RegVal "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0
               Set-RegVal "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 0
               Set-RegVal "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" 0
           } },
        @{ name = "Enable Game Mode"; risky = $false
           desc = "Tells Windows to deprioritize background tasks and Windows Update driver installs while a fullscreen game runs."
           action = { Set-RegVal "HKCU:\Software\Microsoft\GameBar" "AllowAutoGameMode" 1 } },
        @{ name = "Hardware-Accelerated GPU Scheduling"; risky = $false
           desc = "Lets the GPU manage its own memory queue instead of relying on the CPU scheduler. Reduces input latency on supported GPUs (RTX 20-series+). Needs a restart to take effect."
           action = { Set-RegVal "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2 } },
        @{ name = "Ultimate Performance power plan"; risky = $false
           desc = "Removes CPU parking and power-saving throttling. Higher idle power draw, but no CPU core sits half-asleep when a game suddenly needs it."
           action = {
               powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null | Out-Null
               $p = powercfg /list 2>$null | Select-String "Ultimate"
               if ($p) { powercfg /setactive (($p.ToString() -split '\s+')[3]) 2>$null }
               else { powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null }
           } },
        @{ name = "Disable Fullscreen Optimizations globally"; risky = $false
           desc = "Fullscreen Optimizations forces borderless-windowed behavior under the hood, adding a compositor hop -> input delay. This disables it system-wide. Note: for exclusive-fullscreen games you still need to also uncheck it per-exe in the game's .exe Properties > Compatibility tab if it doesn't take."
           action = { Set-RegVal "HKCU:\System\GameConfigStore" "GameDVR_FSEBehavior" 2 } },
        @{ name = "MMCSS: prioritize foreground game"; risky = $false
           desc = "Tells the Multimedia Class Scheduler to give the focused game higher CPU/GPU task priority over background processes."
           action = {
               $p = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
               Set-RegVal $p "GPU Priority" 8
               Set-RegVal $p "Priority" 6
               Set-RegVal $p "Scheduling Category" "High" "String"
               Set-RegVal $p "SFIO Priority" "High" "String"
               Set-RegVal "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 0
           } },
        @{ name = "Disable visual effects (animations/shadows)"; risky = $false
           desc = "Turns off window fade, menu delay, listview shadow, drag-full-window rendering. Small but free GPU/compositor overhead removed."
           action = {
               Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 2
               Set-RegVal "HKCU:\Control Panel\Desktop" "DragFullWindows" "0" "String"
               Set-RegVal "HKCU:\Control Panel\Desktop" "MenuShowDelay" "0" "String"
               Set-RegVal "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "0" "String"
               Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations" 0
               Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ListviewAlphaSelect" 0
               Set-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ListviewShadow" 0
           } }
    )

    "Network / Ping / Delay" = @(
        @{ name = "Disable Nagle's Algorithm"; risky = $false
           desc = "Nagle's algorithm batches small outgoing TCP packets to reduce packet count, adding up to ~200ms of buffering delay. This forces immediate send -- the single biggest ping-consistency fix on this list."
           action = {
               Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -EA 0 | ForEach-Object {
                   Set-RegVal $_.PSPath "TcpAckFrequency" 1
                   Set-RegVal $_.PSPath "TCPNoDelay" 1
               }
           } },
        @{ name = "Disable Network Throttling Index"; risky = $false
           desc = "Windows caps non-multimedia network throughput by default (originally to protect audio/video streaming). Removes that cap."
           action = { Set-RegVal "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 0xffffffff } },
        @{ name = "Remove QoS reserved bandwidth"; risky = $false
           desc = "Windows reserves 20% of bandwidth for QoS-tagged traffic by default, unused by most home setups. Sets it to 0% so games get full bandwidth."
           action = { Set-RegVal "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" "NonBestEffortLimit" 0 } },
        @{ name = "TCP stack tuning (autotune/ECN/congestion)"; risky = $false
           desc = "Sets TCP autotuning to normal, disables ECN (some routers mishandle ECN-marked packets causing drops), switches congestion provider to CTCP for better throughput recovery after packet loss."
           action = {
               netsh int tcp set global autotuninglevel=normal 2>$null | Out-Null
               netsh int tcp set global ecncapability=disabled 2>$null | Out-Null
               netsh int tcp set global rss=enabled 2>$null | Out-Null
               netsh int tcp set heuristics disabled 2>$null | Out-Null
               netsh int tcp set supplemental Internet congestionprovider=ctcp 2>$null | Out-Null
           } },
        @{ name = "Disable NIC power saving"; risky = $false
           desc = "Stops Windows from letting your network adapter enter a low-power state to save energy, which causes brief ping spikes when it wakes back up mid-session."
           action = { Get-NetAdapter -EA 0 | ForEach-Object { Disable-NetAdapterPowerManagement -Name $_.Name -EA 0 } } },
        @{ name = "Set fast public DNS (Cloudflare 1.1.1.1)"; risky = $false
           desc = "Swaps your DNS resolver to Cloudflare's, which is typically faster than most ISP default resolvers for domain lookups. Doesn't affect in-game ping, only connection/lookup speed."
           action = {
               Get-NetAdapter -EA 0 | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
                   Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses ("1.1.1.1","1.0.0.1") -EA 0
               }
               ipconfig /flushdns 2>$null | Out-Null
           } },
        @{ name = "Disable IPv6 on active adapters"; risky = $true
           desc = "RISKY (situational): fixes routing/ping-spike issues on some ISPs that have broken IPv6 peering, but breaks connectivity if your ISP or game actually requires IPv6. Test alone before relying on it."
           action = {
               Get-NetAdapter -EA 0 | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
                   Disable-NetAdapterBinding -InterfaceAlias $_.Name -ComponentID ms_tcpip6 -EA 0
               }
           } }
    )

    "Background Load (CPU/Disk)" = @(
        @{ name = "Disable DiagTrack (telemetry)"; risky = $false
           desc = "Connected User Experiences and Telemetry service. Constantly collects and uploads usage data in the background. Safe to disable, no functional loss for a home PC."
           action = { Disable-SvcSafe "DiagTrack" } },
        @{ name = "Disable dmwappushservice"; risky = $false
           desc = "WAP push message routing service, a legacy carrier-messaging service unused on desktop PCs. Safe to disable."
           action = { Disable-SvcSafe "dmwappushservice" } },
        @{ name = "Disable Windows Search indexing"; risky = $true
           desc = "RISKY (tradeoff): frees CPU/disk I/O from constant background indexing, but Start Menu / File Explorer search becomes slow (full scan instead of instant index lookup). Skip this if you search your files often."
           action = { Disable-SvcSafe "WSearch" } },
        @{ name = "Disable Superfetch/SysMain"; risky = $true
           desc = "RISKY (SSD/NVMe only): SysMain preloads frequently-used apps into RAM for faster launch. Disabling helps SSDs (avoids unnecessary write cycles) but can slow app launches back down on a mechanical HDD. Only enable this checkbox if your OS drive is SSD/NVMe."
           action = { Disable-SvcSafe "SysMain" } },
        @{ name = "Auto-managed page file"; risky = $false
           desc = "Lets Windows size the page file dynamically instead of a fixed size, generally the safest and most stable setting."
           action = {
               try {
                   $cs = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges -EA 0
                   if ($cs) { $cs.AutomaticManagedPagefile = $true; $cs.Put() | Out-Null }
               } catch {}
           } },
        @{ name = "Clean temp files"; risky = $false
           desc = "Clears %TEMP% and C:\Windows\Temp. Frees disk space, no functional risk -- these are meant to be temporary."
           action = {
               Remove-Item -Path "$env:temp\*" -Recurse -Force -EA 0 | Out-Null
               Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -EA 0 | Out-Null
           } }
    )

    "System-Altering (opt-in only)" = @(
        @{ name = "Disable Windows Update service"; risky = $true
           desc = "WARNING: stops your PC from receiving security patches entirely until manually re-enabled. Does not meaningfully affect FPS -- Update only spikes CPU/disk during actual patch installs, which you can just schedule around. Not recommended to leave off long-term."
           action = { Disable-SvcSafe "wuauserv"; Disable-SvcSafe "UsoSvc" } },
        @{ name = "Disable Windows Defender real-time protection"; risky = $true
           desc = "WARNING: removes active malware protection. Can reduce background scan CPU usage slightly, but leaves you unprotected unless you run separate AV. Not recommended unless you know what you're doing."
           action = { Set-RegVal "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" "DisableAntiSpyware" 1 } },
        @{ name = "Disable Hyper-V"; risky = $true
           desc = "WARNING: breaks WSL2, Docker, and Windows Sandbox if you use any of them. Also breaks some anti-cheat systems (EAC/BattlEye/Vanguard) that rely on virtualization-based security -- disabling Hyper-V can make certain anti-cheat games refuse to launch, not just fail to help them. Only useful if you don't use virtualization and don't play VBS-locked titles."
           action = { Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart -EA 0 } }
    )
}

# ---------------------------------------------------------------
#  GUI
# ---------------------------------------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Anki's Windows Toolbox"
$form.Size = New-Object System.Drawing.Size(920, 700)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(24,24,27)
$form.ForeColor = [System.Drawing.Color]::White
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "ANKI'S WINDOWS TOOLBOX"
$titleLabel.Location = New-Object System.Drawing.Point(15,12)
$titleLabel.Size = New-Object System.Drawing.Size(880,28)
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 15, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(90,200,255)
$form.Controls.Add($titleLabel)

$subLabel = New-Object System.Windows.Forms.Label
$subLabel.Text = "Check the tweaks you want, then hit Apply Selected. Red-flagged items are unchecked on purpose -- read before enabling."
$subLabel.Location = New-Object System.Drawing.Point(15,42)
$subLabel.Size = New-Object System.Drawing.Size(880,20)
$subLabel.ForeColor = [System.Drawing.Color]::Gray
$form.Controls.Add($subLabel)

# Tabs, one per category
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Location = New-Object System.Drawing.Point(15,70)
$tabControl.Size = New-Object System.Drawing.Size(880,430)

# map: checkbox control -> tweak hashtable, used at Apply time
$script:CheckboxMap = @()

foreach ($catName in $Categories.Keys) {
    $tab = New-Object System.Windows.Forms.TabPage
    $tab.Text = $catName
    $tab.BackColor = [System.Drawing.Color]::FromArgb(32,32,36)

    $panel = New-Object System.Windows.Forms.Panel
    $panel.Dock = "Fill"
    $panel.AutoScroll = $true
    $tab.Controls.Add($panel)

    $y = 10
    foreach ($tweak in $Categories[$catName]) {
        $cb = New-Object System.Windows.Forms.CheckBox
        $cb.Text = $tweak.name
        $cb.Location = New-Object System.Drawing.Point(12, $y)
        $cb.Size = New-Object System.Drawing.Size(820, 22)
        $cb.ForeColor = if ($tweak.risky) { [System.Drawing.Color]::FromArgb(255,120,90) } else { [System.Drawing.Color]::White }
        $cb.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
        $cb.Checked = -not $tweak.risky
        $panel.Controls.Add($cb)
        $y += 24

        $descLbl = New-Object System.Windows.Forms.Label
        $descLbl.Text = $tweak.desc
        $descLbl.Location = New-Object System.Drawing.Point(30, $y)
        $descLbl.Size = New-Object System.Drawing.Size(800, 34)
        $descLbl.ForeColor = [System.Drawing.Color]::FromArgb(170,170,170)
        $descLbl.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
        $panel.Controls.Add($descLbl)
        $y += 42

        $script:CheckboxMap += [PSCustomObject]@{ Checkbox = $cb; Tweak = $tweak; Category = $catName }
    }

    $tabControl.TabPages.Add($tab)
}
$form.Controls.Add($tabControl)

# Status / log box
$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Location = New-Object System.Drawing.Point(15,510)
$logBox.Size = New-Object System.Drawing.Size(880,90)
$logBox.Multiline = $true
$logBox.ScrollBars = "Vertical"
$logBox.ReadOnly = $true
$logBox.BackColor = [System.Drawing.Color]::FromArgb(18,18,20)
$logBox.ForeColor = [System.Drawing.Color]::FromArgb(140,220,140)
$logBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$logBox.Text = "Ready. Select tweaks across tabs, then Apply Selected."
$form.Controls.Add($logBox)

function Write-Log($msg) {
    $logBox.AppendText("`r`n$msg")
    $logBox.SelectionStart = $logBox.Text.Length
    $logBox.ScrollToCaret()
}

# Buttons
$btnPanel = New-Object System.Windows.Forms.Panel
$btnPanel.Location = New-Object System.Drawing.Point(15,610)
$btnPanel.Size = New-Object System.Drawing.Size(880,50)
$form.Controls.Add($btnPanel)

$applyBtn = New-Object System.Windows.Forms.Button
$applyBtn.Text = "Apply Selected"
$applyBtn.Location = New-Object System.Drawing.Point(0,0)
$applyBtn.Size = New-Object System.Drawing.Size(180,38)
$applyBtn.BackColor = [System.Drawing.Color]::FromArgb(0,150,80)
$applyBtn.ForeColor = [System.Drawing.Color]::White
$applyBtn.FlatStyle = "Flat"
$applyBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$applyBtn.Add_Click({
    $selected = $script:CheckboxMap | Where-Object { $_.Checkbox.Checked }
    if ($selected.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Nothing selected.", "Anki's Toolbox", "OK", "Information") | Out-Null
        return
    }
    $riskyCount = ($selected | Where-Object { $_.Tweak.risky }).Count
    if ($riskyCount -gt 0) {
        $r = [System.Windows.Forms.MessageBox]::Show("$riskyCount risky/system-altering tweak(s) are selected. These can affect security or virtualization features. Continue?", "Confirm risky tweaks", "YesNo", "Warning")
        if ($r -ne "Yes") { return }
    }
    Write-Log "--- Applying $($selected.Count) tweak(s) ---"
    foreach ($item in $selected) {
        Write-Log "-> $($item.Tweak.name)"
        try {
            & $item.Tweak.action
        } catch {
            Write-Log "   ERROR: $_"
        }
    }
    Write-Log "--- Done. Restart recommended for full effect. ---"
    [System.Windows.Forms.MessageBox]::Show("Applied $($selected.Count) tweak(s). Restart your PC for everything to take effect.", "Complete", "OK", "Information") | Out-Null
})
$btnPanel.Controls.Add($applyBtn)

$restoreBtn = New-Object System.Windows.Forms.Button
$restoreBtn.Text = "Create Restore Point"
$restoreBtn.Location = New-Object System.Drawing.Point(190,0)
$restoreBtn.Size = New-Object System.Drawing.Size(180,38)
$restoreBtn.BackColor = [System.Drawing.Color]::FromArgb(180,130,0)
$restoreBtn.ForeColor = [System.Drawing.Color]::White
$restoreBtn.FlatStyle = "Flat"
$restoreBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$restoreBtn.Add_Click({
    Write-Log "Creating system restore point..."
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -EA 0
        Checkpoint-Computer -Description "AnkiToolbox-PreTweak" -RestorePointType "MODIFY_SETTINGS" -EA 0
        Write-Log "Restore point created."
        [System.Windows.Forms.MessageBox]::Show("Restore point created.", "Success", "OK", "Information") | Out-Null
    } catch {
        Write-Log "Restore point failed (may be disabled by group policy)."
        [System.Windows.Forms.MessageBox]::Show("Failed to create restore point.", "Error", "OK", "Error") | Out-Null
    }
})
$btnPanel.Controls.Add($restoreBtn)

$restartBtn = New-Object System.Windows.Forms.Button
$restartBtn.Text = "Restart PC"
$restartBtn.Location = New-Object System.Drawing.Point(380,0)
$restartBtn.Size = New-Object System.Drawing.Size(140,38)
$restartBtn.BackColor = [System.Drawing.Color]::FromArgb(180,0,0)
$restartBtn.ForeColor = [System.Drawing.Color]::White
$restartBtn.FlatStyle = "Flat"
$restartBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$restartBtn.Add_Click({
    $r = [System.Windows.Forms.MessageBox]::Show("Restart computer now?", "Confirm", "YesNo", "Question")
    if ($r -eq "Yes") { Restart-Computer -Force }
})
$btnPanel.Controls.Add($restartBtn)

$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
