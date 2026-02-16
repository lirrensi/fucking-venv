# FuckingVenv installer for PowerShell
#
# Usage:
#   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force; iwr -UseBasicParsing https://.../install.ps1 | iex
#
# What it does:
#   1. Appends venv function to your PowerShell profile
#   2. Defines it RIGHT NOW so it works immediately

param()

$ErrorActionPreference = "Stop"

$MarkerStart = "# >>> fuckingvenv >>>"
$MarkerEnd = "# <<< fuckingvenv <<<"

$VenvFunction = @'
function venv {
    param([string]$Name)
    
    $candidates = @(".venv", "venv", "env", ".env")
    
    if ($Name) {
        # Dot-agnostic: .foo matches foo and vice versa
        $cleanTarget = $Name.TrimStart(".")
        Get-ChildItem -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $cleanName = $_.Name.TrimStart(".")
            if ($cleanName -eq $cleanTarget) {
                $activate = Join-Path $_.FullName "Scripts\Activate.ps1"
                if (Test-Path $activate) {
                    Write-Host "Activating: $($_.Name)" -ForegroundColor Green
                    . $activate
                    return
                }
            }
        }
        Write-Host "No venv found: $Name" -ForegroundColor Red
        return
    }
    
    # No argument: try candidates
    foreach ($c in $candidates) {
        $activate = Join-Path $PWD "$c\Scripts\Activate.ps1"
        if (Test-Path $activate) {
            Write-Host "Activating: $c" -ForegroundColor Green
            . $activate
            return
        }
    }
    
    # Search all folders
    Get-ChildItem -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $activate = Join-Path $_.FullName "Scripts\Activate.ps1"
        if (Test-Path $activate) {
            Write-Host "Activating: $($_.Name)" -ForegroundColor Green
            . $activate
            return
        }
    }
    
    Write-Host "No venv found here" -ForegroundColor Red
}
'@

# Get profile path - handle Windows PowerShell vs PowerShell Core
$ProfilePath = $PROFILE.CurrentUserCurrentHost
if (-not $ProfilePath) {
    # Detect PowerShell version and set appropriate path
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        # PowerShell Core (6+)
        $ProfilePath = Join-Path $env:USERPROFILE "Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
    } else {
        # Windows PowerShell (5.1)
        $ProfilePath = Join-Path $env:USERPROFILE "Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
    }
}

Write-Host "Target profile: $ProfilePath"

# Create directory if needed
$ProfileDir = Split-Path $ProfilePath -Parent
if (-not (Test-Path $ProfileDir)) {
    New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
    Write-Host "Created profile directory"
}

# Check if already installed in profile
$alreadyInProfile = $false
if (Test-Path $ProfilePath) {
    $content = Get-Content $ProfilePath -Raw -ErrorAction SilentlyContinue
    if ($content -and $content.Contains($MarkerStart)) {
        $alreadyInProfile = $true
    }
}

if ($alreadyInProfile) {
    Write-Host "Already in profile!"
} else {
    # Append to profile
    $block = @"

$MarkerStart
$VenvFunction
$MarkerEnd
"@
    Add-Content -Path $ProfilePath -Value $block -Encoding UTF8
    Write-Host "Added to profile!"
}

# Define function directly in memory (works immediately!)
. ([ScriptBlock]::Create($VenvFunction))

Write-Host ""
Write-Host "Done! Try: venv"
