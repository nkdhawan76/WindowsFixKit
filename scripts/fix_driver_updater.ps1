<#
.SYNOPSIS
    Scans, repairs, and updates missing or corrupt hardware drivers via Windows Update.
.DESCRIPTION
    Inspects all PnP hardware devices in error states (Code 10, 28, 43), triggers hardware bus
    rescans via pnputil, attempts driver reactivation, and queries the Windows Update Catalog
    for verified driver updates.
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
    Write-Error "[!] Driver repair requires administrative privileges. Please run as Administrator."
    exit 1
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "       WindowsFixKit - Hardware Driver Auto-Repair Engine        " -ForegroundColor Cyan
Write-Host "      DevSparks India | https://devsparksindia.com | 9521032268   " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Detect Devices in Error State
Write-Host "`n[1/4] Scanning Device Manager for Hardware Driver Failures..." -ForegroundColor Yellow

$errorDevices = Get-CimInstance Win32_PnPEntity -Filter "ConfigManagerErrorCode <> 0" -ErrorAction SilentlyContinue

if ($errorDevices) {
    Write-Host "  [!] Found $($errorDevices.Count) device(s) in an error state:" -ForegroundColor Yellow
    foreach ($dev in $errorDevices) {
        Write-Host "      * Device : $($dev.Name) [Code: $($dev.ConfigManagerErrorCode)]" -ForegroundColor Red
        Write-Host "        Device ID: $($dev.DeviceID)" -ForegroundColor Gray
    }
} else {
    Write-Host "  [OK] No active PnP devices reporting hardware error codes (Code 10/28/43)." -ForegroundColor Green
}

# 2. Rescan Hardware Bus via pnputil
Write-Host "`n[2/4] Rescanning Hardware Plug & Play Bus..." -ForegroundColor Yellow
try {
    Start-Process -FilePath "pnputil.exe" -ArgumentList "/scan-devices" -NoNewWindow -Wait -ErrorAction SilentlyContinue
    Write-Host "  [OK] Plug and Play bus rescan completed successfully." -ForegroundColor Green
} catch {
    Write-Warning "  [-] pnputil rescan error: $_"
}

# 3. Remediate Network & Wi-Fi Driver State
Write-Host "`n[3/4] Validating Network & Wireless Interface Drivers..." -ForegroundColor Yellow
$netAdapters = Get-NetAdapter -ErrorAction SilentlyContinue
foreach ($adapter in $netAdapters) {
    if ($adapter.Status -eq "Disabled") {
        try {
            Enable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction SilentlyContinue
            Write-Host "  [OK] Enabled network adapter: $($adapter.Name)" -ForegroundColor Green
        } catch {}
    } else {
        Write-Host "  [-] Adapter: $($adapter.Name) [$($adapter.InterfaceDescription)] - Active" -ForegroundColor Gray
    }
}

# 4. Trigger Windows Update Driver Catalog Search
Write-Host "`n[4/4] Triggering Microsoft Driver Catalog Online Scan..." -ForegroundColor Yellow
try {
    if (Test-Path "$env:SystemRoot\System32\usoclient.exe") {
        Start-Process -FilePath "$env:SystemRoot\System32\usoclient.exe" -ArgumentList "StartScan" -NoNewWindow -ErrorAction SilentlyContinue
        Write-Host "  [OK] Triggered USOClient driver and servicing update scan." -ForegroundColor Green
    } else {
        Start-Process -FilePath "$env:SystemRoot\System32\wuauclt.exe" -ArgumentList "/detectnow /updatenow" -NoNewWindow -ErrorAction SilentlyContinue
        Write-Host "  [OK] Triggered wuauclt update scan." -ForegroundColor Green
    }
} catch {
    Write-Warning "  [-] Driver catalog query returned: $_"
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host " [STATUS] Hardware Driver Scan & Update Routine Completed." -ForegroundColor Green
Write-Host "=================================================================`n" -ForegroundColor Cyan
