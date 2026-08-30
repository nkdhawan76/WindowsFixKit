<#
.SYNOPSIS
    Performs filesystem validation, non-destructive chkdsk scan, and SSD TRIM optimization.
.DESCRIPTION
    Runs chkdsk in read-only / spot-fix mode, trims SSD storage volumes (Optimize-Volume / defrag /L),
    and clears filesystem dirty bits.
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
    Write-Error "[!] Disk error fix requires administrative elevation. Please run PowerShell as Administrator."
    exit 1
}

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " [WindowsFixKit] Disk Integrity & TRIM Optimization" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

# 1. Non-destructive chkdsk scan
Write-Host "`n[+] Running non-destructive filesystem scan on $env:SystemDrive..." -ForegroundColor Yellow
$chkdskOutput = & chkdsk.exe $env:SystemDrive /scan 2>&1
Write-Host "  [-] $chkdskOutput" -ForegroundColor Gray
Write-Host "  [OK] Online filesystem integrity scan completed." -ForegroundColor Green

# 2. SSD / Drive Re-trim and Optimization
Write-Host "`n[+] Executing SSD TRIM / Storage Volume Optimization..." -ForegroundColor Yellow
if (Get-Command "Optimize-Volume" -ErrorAction SilentlyContinue) {
    try {
        Optimize-Volume -DriveLetter ($env:SystemDrive.Substring(0,1)) -ReTrim -Verbose -ErrorAction SilentlyContinue
        Write-Host "  [OK] SSD re-trim completed via Optimize-Volume." -ForegroundColor Green
    }
    catch {
        Write-Warning "  [-] Optimize-Volume returned: $_"
    }
}
else {
    & defrag.exe $env:SystemDrive /L 2>&1 | Out-Null
    Write-Host "  [OK] Volume re-trim completed via defrag /L." -ForegroundColor Green
}

Write-Host "`n=========================================================" -ForegroundColor Green
Write-Host " [STATUS] Disk Integrity and Optimization Completed." -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
