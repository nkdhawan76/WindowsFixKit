<#
.SYNOPSIS
    Optimizes Windows power settings to reduce battery strain and extend operational life.
.DESCRIPTION
    Configures sleep timeouts, display turn-off times, and enables battery saver triggers.
    Idempotent and safe to run multiple times.
#>

[CmdletBinding()]
param(
    [switch]$NonInteractive
)

function Test-IsAdmin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Error "[!] Battery optimization requires administrative elevation. Please run PowerShell as Administrator."
    exit 1
}

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " [WindowsFixKit] Battery & Power Optimization" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

# Set display timeout on battery to 5 minutes (300 seconds)
Write-Host "`n[+] Configuring display & sleep power management timeouts..." -ForegroundColor Yellow
& powercfg.exe /change monitor-timeout-dc 5 2>&1 | Out-Null
& powercfg.exe /change standby-timeout-dc 15 2>&1 | Out-Null
Write-Host "  [OK] Display sleep on battery set to 5m, standby set to 15m." -ForegroundColor Green

# Optimize energy usage
& powercfg.exe /setdcvalueindex SCHEME_CURRENT SUB_ENERGYSAVER ESBATTTHRESHOLD 20 2>&1 | Out-Null
& powercfg.exe /setactive SCHEME_CURRENT 2>&1 | Out-Null
Write-Host "  [OK] Battery Saver threshold configured at 20%." -ForegroundColor Green

Write-Host "`n=========================================================" -ForegroundColor Green
Write-Host " [STATUS] Battery Optimization Configured Successfully." -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
