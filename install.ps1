# FuckingVenv installer for PowerShell
#
# Usage:
#   iex (iwr https://.../install.ps1)
#
# What it does:
#   1. Appends venv function to your PowerShell profile
#   2. Sources it RIGHT NOW so it works immediately

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
                    Write-Host "✨ Activating: $($_.Name)" -ForegroundColor Green
                    . $activate
                    return
                }
            }
        }
        Write-Host "💔 No venv found: $Name" -ForegroundColor Red
        return
    }
    
    # No argument: try candidates
    foreach ($c in $candidates) {
        $activate = Join-Path $PWD "$c\Scripts\Activate.ps1"
        if (Test-Path $activate) {
            Write-Host "✨ Activating: $c" -ForegroundColor Green
            . $activate
            return
        }
    }
    
    # Search all folders
    Get-ChildItem -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $activate = Join-Path $_.FullName "Scripts\Activate.ps1"
        if (Test-Path $activate) {
            Write-Host "✨ Activating: $($_.Name)" -ForegroundColor Green
            . $activate
            return
        }
    }
    
    Write-Host "💔 No venv found here" -ForegroundColor Red
}
'@

# Get profile path
$ProfilePath = $PROFILE.CurrentUserCurrentHost
if (-not $ProfilePath) {
    $ProfilePath = Join-Path $env:USERPROFILE "Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
}

Write-Host "🐾 Target profile: $ProfilePath"

# Create directory if needed
$ProfileDir = Split-Path $ProfilePath -Parent
if (-not (Test-Path $ProfileDir)) {
    New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
}

# Check if already installed
if (Test-Path $ProfilePath) {
    $content = Get-Content $ProfilePath -Raw -ErrorAction SilentlyContinue
    if ($content -and $content.Contains($MarkerStart)) {
        Write-Host "✨ Already installed! Reloading profile..."
        . $ProfilePath
        Write-Host "✨ Done! Try: venv"
        return
    }
}

# Append to profile
$block = @"

$MarkerStart
$VenvFunction
$MarkerEnd
"@

Add-Content -Path $ProfilePath -Value $block -Encoding UTF8

# Source it NOW
. $ProfilePath

Write-Host ""
Write-Host "✨ Installed! The 'venv' command is ready."
Write-Host "   Try it: venv"
Write-Host ""
Write-Host "   (Already loaded in this shell - no restart needed!)"
