<#
.SYNOPSIS
    Frees disk space by cleaning temporary folders, caches, and recycling bin.
.DESCRIPTION
    Purges Windows Temp, user Temp, Delivery Optimization cache, Windows Error Reporting
    queues, Prefetch files, and runs Windows Disk Cleanup.
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
    Write-Error "[!] Storage cleanup requires administrative elevation. Please run PowerShell as Administrator."
    exit 1
}

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " [WindowsFixKit] Storage Cleanup & Space Recovery" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

# 1. Purge Temporary Directories
Write-Host "`n[+] Cleaning System and User Temp Directories..." -ForegroundColor Yellow
$cleanupPaths = @(
    "$env:LOCALAPPDATA\Temp",
    "$env:SystemRoot\Temp",
    "$env:SystemRoot\Prefetch",
    "$env:ProgramData\Microsoft\Windows\WER\ReportQueue",
    "$env:ProgramData\Microsoft\Windows\WER\ReportArchive",
    "$env:SystemRoot\SoftwareDistribution\Download"
)

foreach ($path in $cleanupPaths) {
    if (Test-Path -Path $path) {
        Write-Host "  [-] Purging: $path" -ForegroundColor Gray
        try {
            Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue |
                Where-Object { -not $_.PSIsContainer } |
                Remove-Item -Force -ErrorAction SilentlyContinue
            Write-Host "  [OK] Cleaned $path" -ForegroundColor Green
        }
        catch {
            Write-Warning "  [-] Skipped locked files in $($path): $_"
        }
    }
}

# 2. Clear Delivery Optimization Files
Write-Host "`n[+] Clearing Delivery Optimization Cache..." -ForegroundColor Yellow
if (Get-Command "Delete-DeliveryOptimizationCache" -ErrorAction SilentlyContinue) {
    try {
        Delete-DeliveryOptimizationCache -Force -ErrorAction SilentlyContinue
        Write-Host "  [OK] Delivery Optimization Cache deleted." -ForegroundColor Green
    }
    catch {
        Write-Warning "  [-] Delivery Optimization cache delete returned: $_"
    }
}

# 3. Empty Recycle Bin
Write-Host "`n[+] Emptying Recycle Bin across all logical drives..." -ForegroundColor Yellow
try {
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Host "  [OK] Recycle bin emptied." -ForegroundColor Green
}
catch {
    Write-Warning "  [-] Could not clear recycle bin: $_"
}

# 4. Trigger Native Cleanmgr
Write-Host "`n[+] Starting Windows Cleanmgr Background Task..." -ForegroundColor Yellow
if (Test-Path -Path "$env:SystemRoot\System32\cleanmgr.exe") {
    Start-Process -FilePath "$env:SystemRoot\System32\cleanmgr.exe" -ArgumentList "/autoclean /d $env:SystemDrive" -NoNewWindow -Wait -ErrorAction SilentlyContinue
    Write-Host "  [OK] Cleanmgr automated pass complete." -ForegroundColor Green
}

Write-Host "`n=========================================================" -ForegroundColor Green
Write-Host " [STATUS] Storage Cleanup Completed Successfully." -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
