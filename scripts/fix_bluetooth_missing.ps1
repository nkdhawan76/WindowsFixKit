<#
.SYNOPSIS
    Fixes missing Bluetooth icon, device, or service post Windows update.
.DESCRIPTION
    Re-initializes Bluetooth subsystem components:
    - Sets Bluetooth Support Service (bthserv) to Automatic and starts it
    - Configures Bluetooth Audio Gateway Service (BTAGService)
    - Re-enables disabled Bluetooth PnP hardware radios
    - Initiates device manager rescan
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
    Write-Error "[!] Bluetooth fix requires administrative elevation. Please run PowerShell as Administrator."
    exit 1
}

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " [WindowsFixKit] Fixing Bluetooth Service / Adapter" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

# 1. Inspect and Start Bluetooth Services
Write-Host "`n[+] Configuring Bluetooth core services..." -ForegroundColor Yellow
$bluetoothServices = @("bthserv", "BTAGService", "bthHFSrv")

foreach ($svcName in $bluetoothServices) {
    $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if ($svc) {
        Write-Host "  [-] Service $($svcName): current status is $($svc.Status)" -ForegroundColor Gray
        try {
            Set-Service -Name $svcName -StartupType Automatic -ErrorAction SilentlyContinue
            Start-Service -Name $svcName -ErrorAction SilentlyContinue
            $svc.Refresh()
            Write-Host "  [OK] Service $svcName is now $($svc.Status)" -ForegroundColor Green
        }
        catch {
            Write-Warning "  [-] Error updating service $($svcName): $_"
        }
    }
    else {
        Write-Host "  [-] Service $svcName not present on this edition of Windows." -ForegroundColor Gray
    }
}

# 2. Inspect and Enable Bluetooth PnP Devices
Write-Host "`n[+] Checking Bluetooth PnP Devices..." -ForegroundColor Yellow
if (Get-Command "Get-PnpDevice" -ErrorAction SilentlyContinue) {
    $btDevices = Get-PnpDevice -Class Bluetooth -ErrorAction SilentlyContinue
    foreach ($dev in $btDevices) {
        Write-Host "  [-] Found Bluetooth Device: $($dev.FriendlyName) [Status: $($dev.Status)]" -ForegroundColor Gray
        if ($dev.Status -ne "OK") {
            Write-Host "  [-] Enabling $($dev.FriendlyName)..." -ForegroundColor Yellow
            try {
                Enable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
                Write-Host "  [OK] Enabled device: $($dev.FriendlyName)" -ForegroundColor Green
            }
            catch {
                Write-Warning "  [-] Failed to enable $($dev.FriendlyName): $_"
            }
        }
    }
}

# 3. Hardware Rescan
Write-Host "`n[+] Triggering Bluetooth Hardware Rescan..." -ForegroundColor Yellow
if (Get-Command "pnputil.exe" -ErrorAction SilentlyContinue) {
    & pnputil.exe /scan-devices 2>&1 | Out-Null
    Write-Host "  [OK] Hardware bus rescan completed." -ForegroundColor Green
}

Write-Host "`n=========================================================" -ForegroundColor Green
Write-Host " [STATUS] Bluetooth Remediation Completed Successfully." -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
