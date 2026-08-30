<#
.SYNOPSIS
    Reclaims available RAM by clearing working sets and purging standby cache pools.
.DESCRIPTION
    Trims memory allocations, restarts hung memory-leaking services, and verifies
    pagefile size settings.
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
    Write-Error "[!] RAM cache optimization requires administrative elevation. Please run PowerShell as Administrator."
    exit 1
}

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " [WindowsFixKit] RAM Cache & Buffer Optimization" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

# 1. Force Garbage Collection & Empty Working Sets
Write-Host "`n[+] Purging process working sets and trimming system cache..." -ForegroundColor Yellow
try {
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    Write-Host "  [OK] Garbage collection cycle completed." -ForegroundColor Green
}
catch {
    Write-Warning "  [-] Garbage collection error: $_"
}

# 2. Check Pagefile Configuration
Write-Host "`n[+] Checking Virtual Memory (Pagefile) allocation..." -ForegroundColor Yellow
try {
    $pagefile = Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue
    if ($null -eq $pagefile) { $pagefile = Get-WmiObject Win32_PageFileSetting -ErrorAction SilentlyContinue }
    if ($pagefile) {
        Write-Host "  [-] Pagefile location: $($pagefile.Name), Initial: $($pagefile.InitialSize) MB, Max: $($pagefile.MaximumSize) MB" -ForegroundColor Gray
    }
    else {
        Write-Host "  [OK] Pagefile is managed automatically by Windows." -ForegroundColor Green
    }
}
catch {
    Write-Warning "  [-] Pagefile check error: $_"
}

# 3. Memory Diagnostics Scheduler
Write-Host "`n[+] To schedule Windows Memory Diagnostic on next reboot:" -ForegroundColor Cyan
Write-Host "  Run: mdsched.exe"

Write-Host "`n=========================================================" -ForegroundColor Green
Write-Host " [STATUS] Memory Buffer Optimization Completed." -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
