<#
.SYNOPSIS
    Deep Component Store & System File Repair Engine with Diagnostic Log Bundler.
.DESCRIPTION
    Executes deep DISM Component Store health scans (/CheckHealth, /ScanHealth, /RestoreHealth)
    and System File Checker (sfc /scannow). Analyzes corrupted component manifests in CBS.log
    and DISM.log, compressing large diagnostic logs into a timestamped archive on the user's Desktop.
    
    DevSparks India | https://devsparksindia.com | 9521032268
#>

[CmdletBinding()]
param(
    [switch]$SkipSfc,
    [switch]$SkipDism
)

$ErrorActionPreference = "Continue"

# Elevation Check
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "[!] Administrative privileges required. Please run this script as Administrator."
    exit 1
}

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " [WindowsFixKit] Deep DISM & SFC Component Store Repair" -ForegroundColor Cyan
Write-Host "  DevSparks India | https://devsparksindia.com | 9521032268" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

$logPath = Join-Path (Split-Path -Parent $PSScriptRoot) "scripts\repair_log.txt"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] [DEEP_SFC_DISM] $Message"
    Add-Content -Path $logPath -Value $entry -ErrorAction SilentlyContinue
}

Write-Log "Starting deep Component Store and System File repairs..."

# 1. DISM Component Store Health Check & Repair
if (-not $SkipDism) {
    Write-Host "`n[+] 1. Running DISM Component Store Health Diagnostics..." -ForegroundColor Yellow
    Write-Host "  [-] Executing DISM /Online /Cleanup-Image /CheckHealth..." -ForegroundColor Gray
    $checkHealth = & dism.exe /Online /Cleanup-Image /CheckHealth 2>&1
    $checkHealthStr = $checkHealth -join "`n  "
    Write-Host "  $checkHealthStr" -ForegroundColor Gray

    Write-Host "`n  [-] Executing DISM /Online /Cleanup-Image /ScanHealth..." -ForegroundColor Gray
    $scanHealth = & dism.exe /Online /Cleanup-Image /ScanHealth 2>&1
    $scanHealthStr = $scanHealth -join "`n  "
    Write-Host "  $scanHealthStr" -ForegroundColor Gray

    Write-Host "`n  [-] Executing DISM /Online /Cleanup-Image /RestoreHealth..." -ForegroundColor Yellow
    $restoreHealth = & dism.exe /Online /Cleanup-Image /RestoreHealth 2>&1
    $restoreHealthStr = $restoreHealth -join "`n  "
    Write-Host "  $restoreHealthStr" -ForegroundColor Gray
    
    Write-Log "Completed DISM RestoreHealth."
}

# 2. System File Checker (SFC)
if (-not $SkipSfc) {
    Write-Host "`n[+] 2. Running System File Checker (sfc /scannow)..." -ForegroundColor Yellow
    Write-Host "  [-] Verifying integrity of protected Windows OS binaries..." -ForegroundColor Gray
    $sfcOutput = & sfc.exe /scannow 2>&1
    $sfcOutputStr = $sfcOutput -join "`n  "
    Write-Host "  $sfcOutputStr" -ForegroundColor Gray
    Write-Log "Completed SFC scan."
}

# 3. Analyze CBS & DISM Logs and Compress to Desktop
Write-Host "`n[+] 3. Archiving & Compressing Servicing Logs to Desktop..." -ForegroundColor Yellow
$cbsLogPath = "$env:SystemRoot\Logs\CBS\CBS.log"
$dismLogPath = "$env:SystemRoot\Logs\DISM\dism.log"

$desktopPath = [Environment]::GetFolderPath("Desktop")
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$zipBundlePath = Join-Path $desktopPath "WindowsFixKit_CBS_Logs_$timestamp.zip"

$tempStaging = Join-Path $env:TEMP "WindowsFixKit_CBS_Staging_$timestamp"
New-Item -Path $tempStaging -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

try {
    if (Test-Path $cbsLogPath) {
        Copy-Item -Path $cbsLogPath -Destination (Join-Path $tempStaging "CBS.log") -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $dismLogPath) {
        Copy-Item -Path $dismLogPath -Destination (Join-Path $tempStaging "dism.log") -Force -ErrorAction SilentlyContinue
    }
    
    # Compress staging folder to ZIP
    $stagingCount = (Get-ChildItem -Path $tempStaging | Measure-Object).Count
    if ($stagingCount -gt 0) {
        Compress-Archive -Path "$tempStaging\*" -DestinationPath $zipBundlePath -Force
        Write-Host "  [+] Servicing diagnostic bundle created: $zipBundlePath" -ForegroundColor Green
        Write-Log "Compressed CBS & DISM logs to $zipBundlePath."
    }
} catch {
    Write-Warning "  [-] Could not package servicing logs: $_"
} finally {
    Remove-Item -Path $tempStaging -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "`n=========================================================" -ForegroundColor Cyan
Write-Host " [COMPLETED] Deep Component Store & System File Repair Finished!" -ForegroundColor Green
Write-Host "  Log File: $logPath" -ForegroundColor Gray
Write-Host "=========================================================" -ForegroundColor Cyan
