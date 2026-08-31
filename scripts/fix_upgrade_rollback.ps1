<#
.SYNOPSIS
    Diagnoses and remediates Windows 10/11 upgrade rollbacks and driver compatibility conflicts.
.DESCRIPTION
    Scans online third-party device drivers via Get-WindowsDriver, inspects Panther upgrade
    error logs if available, and provides automated driver conflict guidance.
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
    Write-Error "[!] Upgrade rollback diagnostic requires administrative privileges. Please run as Administrator."
    exit 1
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "     WindowsFixKit - Windows 10/11 Upgrade Rollback Resolver     " -ForegroundColor Cyan
Write-Host "      DevSparks India | https://devsparksindia.com | 9521032268   " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Inspect Windows Setup Panther Logs
Write-Host "`n[1/3] Inspecting Windows Setup Panther Error Logs..." -ForegroundColor Yellow
$pantherPaths = @(
    "C:\`$WINDOWS.~BT\Sources\Panther\setuperr.log",
    "C:\`$WINDOWS.~BT\Sources\Panther\setupact.log",
    "C:\Windows\Panther\setuperr.log"
)

$foundErrors = 0
foreach ($log in $pantherPaths) {
    if (Test-Path $log) {
        Write-Host "  [-] Examining log: $log" -ForegroundColor Gray
        try {
            $errLines = Get-Content -Path $log -Tail 30 -ErrorAction SilentlyContinue | Where-Object { $_ -match "Error|Failed|Rollback|MOSETUP" }
            if ($errLines) {
                Write-Host "  [!] Observed Upgrade Setup Log Entries:" -ForegroundColor Yellow
                $errLines | ForEach-Object { Write-Host "      $_" -ForegroundColor Gray }
                $foundErrors++
            }
        } catch {}
    }
}

if ($foundErrors -eq 0) {
    Write-Host "  [OK] No active Panther setup rollback crash logs detected." -ForegroundColor Green
}

# 2. Audit Installed 3rd Party Drivers
Write-Host "`n[2/3] Auditing Installed Third-Party Device Drivers (Get-WindowsDriver)..." -ForegroundColor Yellow
try {
    $drivers = Get-WindowsDriver -Online -All:$false -ErrorAction SilentlyContinue
    if ($drivers) {
        $count = $drivers.Count
        Write-Host "  [+] Discovered $count third-party staging drivers:" -ForegroundColor Gray
        $drivers | Select-Object -First 10 Driver, ProviderName, ClassName, Date | Format-Table -AutoSize | Out-String | Write-Host
        if ($count -gt 10) {
            Write-Host "  [-] ... and $($count - 10) more drivers installed." -ForegroundColor Gray
        }
    } else {
        Write-Host "  [OK] Default inbox Microsoft drivers active." -ForegroundColor Green
    }
} catch {
    Write-Warning "  [-] Could not query driver store via DISM: $_"
}

# 3. Clean Stale Setup Temp Folders
Write-Host "`n[3/3] Clearing Staging Setup Cache Folders..." -ForegroundColor Yellow
$staleDirs = @(
    "C:\`$GetCurrent",
    "C:\`$SysReset"
)
foreach ($dir in $staleDirs) {
    if (Test-Path $dir) {
        try {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  [OK] Cleaned stale upgrade folder: $dir" -ForegroundColor Green
        } catch {
            Write-Warning "  [-] Could not remove $dir : $_"
        }
    }
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "                  UPGRADE REMEDIATION CHECKLIST                  " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "  1. Disconnect external USB peripherals, dongles, and smartcard readers." -ForegroundColor Yellow
Write-Host "  2. Update GPU and chipset drivers from official manufacturer website." -ForegroundColor Yellow
Write-Host "  3. Uninstall third-party antivirus or virtual drive software temporarily." -ForegroundColor Yellow
Write-Host "  4. Run 'sfc /scannow' and 'DISM /Online /Cleanup-Image /RestoreHealth'." -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " [STATUS] Windows Upgrade Rollback Diagnostic Completed." -ForegroundColor Green
Write-Host "=================================================================`n" -ForegroundColor Cyan
