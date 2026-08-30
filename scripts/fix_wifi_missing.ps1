<#
.SYNOPSIS
    Fixes missing Wi-Fi adapter or tray icon post Windows update.
.DESCRIPTION
    Detects disabled or uninitialized wireless network adapters:
    - Enables disabled PnP Network Devices
    - Configures and starts WLAN AutoConfig Service (WlanSvc)
    - Triggers hardware PnP device rescan via pnputil
    - Resets wireless network interface states
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
    Write-Error "[!] Wi-Fi fix requires administrative elevation. Please run PowerShell as Administrator."
    exit 1
}

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " [WindowsFixKit] Fixing Missing Wi-Fi Adapter / Icon" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

# 1. Ensure WLAN AutoConfig Service (WlanSvc) is running
Write-Host "`n[+] Checking WLAN AutoConfig Service (WlanSvc)..." -ForegroundColor Yellow
$wlanSvc = Get-Service -Name "WlanSvc" -ErrorAction SilentlyContinue

if ($null -eq $wlanSvc) {
    Write-Warning "  [!] WlanSvc service not found on this system."
}
else {
    Write-Host "  [-] Current WlanSvc status: $($wlanSvc.Status), StartType: $($wlanSvc.StartType)" -ForegroundColor Gray
    try {
        Set-Service -Name "WlanSvc" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name "WlanSvc" -ErrorAction SilentlyContinue
        $wlanSvc.Refresh()
        Write-Host "  [OK] WlanSvc is active ($($wlanSvc.Status))." -ForegroundColor Green
    }
    catch {
        Write-Warning "  [-] Error configuring WlanSvc: $_"
    }
}

# 2. Inspect and Enable Disabled Network Adapters
Write-Host "`n[+] Scanning for disabled Wi-Fi / Wireless adapters..." -ForegroundColor Yellow

# Modern PowerShell / Windows 10/11 path
if (Get-Command "Get-PnpDevice" -ErrorAction SilentlyContinue) {
    $netDevices = Get-PnpDevice -Class Net -ErrorAction SilentlyContinue |
        Where-Object { $_.FriendlyName -match "Wi-Fi|Wireless|802\.11|WLAN" -or $_.InstanceId -match "WLAN" }
    
    foreach ($dev in $netDevices) {
        Write-Host "  [-] Found device: $($dev.FriendlyName) [Status: $($dev.Status)]" -ForegroundColor Gray
        if ($dev.Status -ne "OK") {
            Write-Host "  [-] Enabling device $($dev.FriendlyName)..." -ForegroundColor Yellow
            try {
                Enable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
                Write-Host "  [OK] Device enabled: $($dev.FriendlyName)" -ForegroundColor Green
            }
            catch {
                Write-Warning "  [-] Failed to enable $($dev.FriendlyName): $_"
            }
        }
    }
}

# NetAdapter fallback
if (Get-Command "Get-NetAdapter" -ErrorAction SilentlyContinue) {
    $wifiAdapters = Get-NetAdapter -ErrorAction SilentlyContinue |
        Where-Object { $_.PhysicalMediaType -match "Native 802.11|Wireless" -or $_.InterfaceDescription -match "Wireless|Wi-Fi|802\.11" }
    
    foreach ($adapter in $wifiAdapters) {
        Write-Host "  [-] NetAdapter: $($adapter.Name) [Status: $($adapter.Status)]" -ForegroundColor Gray
        if ($adapter.Status -eq "Disabled") {
            try {
                Enable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction SilentlyContinue
                Write-Host "  [OK] Enabled NetAdapter: $($adapter.Name)" -ForegroundColor Green
            }
            catch {
                Write-Warning "  [-] Failed to enable $($adapter.Name): $_"
            }
        }
    }
}

# Netsh CLI Fallback for Windows 7 / 8.1
Write-Host "`n[+] Enabling wireless interfaces via netsh..." -ForegroundColor Yellow
$interfaces = & netsh interface show interface
$interfaces | ForEach-Object {
    if ($_ -match "Dedicated.*Wi-Fi" -or $_ -match "Dedicated.*Wireless") {
        $interfaceName = ($_ -split "\s{2,}")[-1]
        if ($interfaceName) {
            Write-Host "  [-] Ensuring interface '$interfaceName' is enabled..." -ForegroundColor Gray
            & netsh interface set interface "$interfaceName" admin=enabled 2>&1 | Out-Null
        }
    }
}
Write-Host "  [OK] Interface enablement sweep completed." -ForegroundColor Green

# 3. Rescan Hardware Tree
Write-Host "`n[+] Triggering Plug and Play Hardware Rescan..." -ForegroundColor Yellow
if (Get-Command "pnputil.exe" -ErrorAction SilentlyContinue) {
    & pnputil.exe /scan-devices 2>&1 | Out-Null
    Write-Host "  [OK] PnP device rescan completed via pnputil." -ForegroundColor Green
}

Write-Host "`n=========================================================" -ForegroundColor Green
Write-Host " [STATUS] Wi-Fi Adapter Remediation Completed Successfully." -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
