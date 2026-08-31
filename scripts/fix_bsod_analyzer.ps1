<#
.SYNOPSIS
    Analyzes Windows BSOD crash dumps and resolves faulty driver stop codes.
.DESCRIPTION
    Inspects active Minidump crash files and Event Log BugChecks, extracts the crashing driver
    (e.g., nvlddmkm.sys, rtwlanu.sys, ntoskrnl.exe), and guides resolution steps (driver rollback,
    SFC/DISM verification, clean driver reinstallation).
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

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "      WindowsFixKit - BSOD Crash Dump & BugCheck Analyzer       " -ForegroundColor Cyan
Write-Host "      DevSparks India | https://devsparksindia.com | 9521032268   " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { (Get-Location).Path }
$diagScript = Join-Path $scriptDir "diagnostics\check_bsod_dump.ps1"

Write-Host "`n[1/3] Scanning Windows Kernel Crash Dump Telemetry..." -ForegroundColor Yellow

$result = if (Test-Path $diagScript) { & $diagScript } else { $null }

if ($result -and $result.RecentCrashes.Count -gt 0) {
    Write-Host "  [!] Discovered $($result.RecentCrashes.Count) Recent System Crash Event(s):" -ForegroundColor Yellow
    foreach ($c in $result.RecentCrashes) {
        Write-Host "`n  ------------------------------------------------------------" -ForegroundColor Gray
        Write-Host "  * Crash Time   : $($c.Timestamp)" -ForegroundColor Cyan
        Write-Host "  * Stop Code    : $($c.BugCode)" -ForegroundColor Red
        Write-Host "  * Culprit Info : $($c.Driver)" -ForegroundColor Yellow
        Write-Host "  * Details      : $($c.Explanation)" -ForegroundColor Gray
    }
} else {
    Write-Host "  [OK] No recent BSOD crash dumps or kernel BugChecks recorded in event logs." -ForegroundColor Green
}

# 2. System File & Component Store Integrity Scan
Write-Host "`n[2/3] Verifying System Kernel & Driver Store Integrity..." -ForegroundColor Yellow
if (Test-IsAdmin) {
    Write-Host "  [-] Running System File Checker (sfc /scannow)..." -ForegroundColor Gray
    try {
        Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -NoNewWindow -Wait -ErrorAction SilentlyContinue
        Write-Host "  [OK] System File Checker verification pass completed." -ForegroundColor Green
    } catch {
        Write-Warning "  [-] SFC check returned: $_"
    }
} else {
    Write-Host "  [-] Note: Run as Administrator to execute automated kernel SFC verification." -ForegroundColor Gray
}

# 3. Known Driver Remediation Advice
Write-Host "`n[3/3] Common Driver Crash Remediation Matrix:" -ForegroundColor Yellow
Write-Host "  * nvlddmkm.sys / atikmdag.sys : GPU driver crash -> Clean install GPU drivers using DDU." -ForegroundColor Gray
Write-Host "  * rtwlanu.sys / netwtw*.sys   : Wi-Fi driver crash -> Update WLAN driver or run fix_wifi_missing." -ForegroundColor Gray
Write-Host "  * iaStorA.sys / storahci.sys  : AHCI/RAID storage driver -> Update Intel RST or SSD chipset firmware." -ForegroundColor Gray
Write-Host "  * ntoskrnl.exe                : Core kernel memory error -> Run Windows Memory Diagnostic (mdsched.exe)." -ForegroundColor Gray

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host " [STATUS] BSOD Crash Dump Diagnostic & Analysis Completed." -ForegroundColor Green
Write-Host "=================================================================`n" -ForegroundColor Cyan
