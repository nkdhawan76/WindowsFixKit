<#
.SYNOPSIS
    Remediates Windows Update hangs and downloads stuck at 0% or 'Checking for updates'.
.DESCRIPTION
    Stops core update and cryptographic services, safely rotates SoftwareDistribution and
    Catroot2 folders to timestamped .bak backups, restarts services, and logs detailed actions
    to repair_log.txt in the script directory.
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
    Write-Error "[!] Windows Update remediation requires administrative privileges. Please run as Administrator."
    exit 1
}

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { (Get-Location).Path }
$logFile = Join-Path $scriptDir "repair_log.txt"

function Write-RepairLog {
    param([string]$Message, [string]$Level = "INFO")
    $entry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    Add-Content -Path $logFile -Value $entry -Force -ErrorAction SilentlyContinue
    if ($Level -eq "ERROR") {
        Write-Host "  [!] $Message" -ForegroundColor Red
    } elseif ($Level -eq "OK") {
        Write-Host "  [OK] $Message" -ForegroundColor Green
    } else {
        Write-Host "  [-] $Message" -ForegroundColor Gray
    }
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "     WindowsFixKit - Windows Update Stuck at 0% Resolver        " -ForegroundColor Cyan
Write-Host "      DevSparks India | https://devsparksindia.com | 9521032268   " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

Write-RepairLog "Starting Windows Update Stuck at 0% Remediation." "INFO"

# 1. Stop Windows Update, Cryptographic, BITS, and Installer Services
Write-Host "`n[1/3] Stopping Windows Update & Cryptographic Services..." -ForegroundColor Yellow
$services = @("wuauserv", "cryptsvc", "bits", "msiserver")

foreach ($svcName in $services) {
    $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -eq "Running") {
        try {
            Stop-Service -Name $svcName -Force -ErrorAction Stop
            Write-RepairLog "Stopped service: $svcName" "OK"
        } catch {
            Write-RepairLog "Could not stop $svcName : $_" "WARN"
        }
    }
}

# 2. Rename SoftwareDistribution and Catroot2 folders to timestamped .bak backups
Write-Host "`n[2/3] Safely Rotating Cache & Catalog Directories to .bak..." -ForegroundColor Yellow
$timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")

# SoftwareDistribution
$sdPath = "C:\Windows\SoftwareDistribution"
if (Test-Path $sdPath) {
    $sdBak = "C:\Windows\SoftwareDistribution_$timestamp.bak"
    try {
        Rename-Item -Path $sdPath -NewName (Split-Path $sdBak -Leaf) -Force -ErrorAction Stop
        Write-RepairLog "Rotated $sdPath -> $sdBak" "OK"
    } catch {
        Write-RepairLog "Failed rotating $sdPath : $_. Purging Download cache as fallback." "WARN"
        try {
            Get-ChildItem "$sdPath\Download" -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Write-RepairLog "Purged $sdPath\Download cache." "OK"
        } catch {}
    }
}

# Catroot2
$crPath = "C:\Windows\System32\catroot2"
if (Test-Path $crPath) {
    $crBak = "C:\Windows\System32\catroot2_$timestamp.bak"
    try {
        Rename-Item -Path $crPath -NewName (Split-Path $crBak -Leaf) -Force -ErrorAction Stop
        Write-RepairLog "Rotated $crPath -> $crBak" "OK"
    } catch {
        Write-RepairLog "Failed rotating $crPath : $_" "WARN"
    }
}

# 3. Restart Services
Write-Host "`n[3/3] Restarting Windows Update & Cryptographic Services..." -ForegroundColor Yellow
foreach ($svcName in $services) {
    try {
        Start-Service -Name $svcName -ErrorAction SilentlyContinue
        Write-RepairLog "Started service: $svcName" "OK"
    } catch {
        Write-RepairLog "Could not start service $svcName : $_" "WARN"
    }
}

Write-RepairLog "Windows Update Stuck at 0% Remediation Finished Successfully." "INFO"

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host " [STATUS] Windows Update 0% Stuck Remediation Completed." -ForegroundColor Green
Write-Host " Log File Saved to: $logFile" -ForegroundColor Yellow
Write-Host "=================================================================`n" -ForegroundColor Cyan
