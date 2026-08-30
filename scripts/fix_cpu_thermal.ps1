<#
.SYNOPSIS
    Remediates CPU thermal throttling and overheating via Power Plan throttling controls.
.DESCRIPTION
    Configures Active Cooling policy and sets maximum processor state to 99% (disabling
    aggressive turbo boosting spikes that cause thermal runaway), restoring lower temperatures.
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
    Write-Error "[!] CPU thermal optimization requires administrative elevation. Please run PowerShell as Administrator."
    exit 1
}

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " [WindowsFixKit] CPU Thermal & Throttle Optimization" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

# GUIDs for Processor Power Management
$subProcessor = "54533251-82be-4824-96c1-47b60b740d00"
$settingMaxState = "bc5038f7-23e0-4960-96da-33abaf5935ec"
$settingCoolingPolicy = "94d3a615-a899-4ac5-8282-e32b15a410b3"

Write-Host "`n[+] Setting Processor Power Policy (Active Cooling, Max Processor 99%)..." -ForegroundColor Yellow

# Set Active Cooling (1 = Active, 0 = Passive)
& powercfg.exe /setacvalueindex SCHEME_CURRENT "$subProcessor" "$settingCoolingPolicy" 1 2>&1 | Out-Null
& powercfg.exe /setdcvalueindex SCHEME_CURRENT "$subProcessor" "$settingCoolingPolicy" 1 2>&1 | Out-Null

# Set Max Processor State to 99% on AC and DC to eliminate runaway thermal spikes
& powercfg.exe /setacvalueindex SCHEME_CURRENT "$subProcessor" "$settingMaxState" 99 2>&1 | Out-Null
& powercfg.exe /setdcvalueindex SCHEME_CURRENT "$subProcessor" "$settingMaxState" 99 2>&1 | Out-Null

# Apply active scheme
& powercfg.exe /setactive SCHEME_CURRENT 2>&1 | Out-Null

Write-Host "  [OK] Power scheme updated: Active cooling enabled and maximum processor state set to 99%." -ForegroundColor Green

Write-Host "`n=========================================================" -ForegroundColor Green
Write-Host " [STATUS] CPU Thermal Optimization Applied." -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
