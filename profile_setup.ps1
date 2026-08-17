# PowerShell Profile Setup for Anki Toolbox
# Add this to your PowerShell profile to enable: CTT TOOLS

# Get PowerShell Profile path
$profilePath = $PROFILE.CurrentUserCurrentHost

# Create profile directory if it doesn't exist
$profileDir = Split-Path $profilePath -Parent
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

# Add function to profile if not already present
$functionText = @'
function CTT {
    param([string]$Command = "TOOLS")
    
    $command = $command.ToUpper()
    
    switch ($command) {
        "TOOLS" {
            # Method 1: From GitHub (recommended for remote use)
            irm https://raw.githubusercontent.com/AnKi-code-design/Anki-ToolBox/main/AnkiToolbox.ps1 | iex
            
            # Method 2: From local file (if cloned locally)
            # & "C:\path\to\Anki-ToolBox\AnkiToolbox.ps1"
        }
        default {
            Write-Host "Unknown command: $command" -ForegroundColor Red
            Write-Host "Usage: CTT TOOLS" -ForegroundColor Yellow
        }
    }
}
'@

# Check if function already exists in profile
if (-not (Test-Path $profilePath)) {
    # Create new profile
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
    Add-Content $profilePath $functionText
    Write-Host "[+] PowerShell profile created at: $profilePath" -ForegroundColor Green
} else {
    $profileContent = Get-Content $profilePath
    if ($profileContent -notlike "*function CTT*") {
        Add-Content $profilePath "`n`n$functionText"
        Write-Host "[+] CTT function added to profile: $profilePath" -ForegroundColor Green
    } else {
        Write-Host "[*] CTT function already exists in profile" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Setup complete! Restart PowerShell and use: CTT TOOLS" -ForegroundColor Green
