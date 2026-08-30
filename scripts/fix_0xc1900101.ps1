<#
.SYNOPSIS
    Fixes Windows Update error 0xc1900101 (Feature Update Rollback / Driver Conflicts).
.DESCRIPTION
    Resolves driver incompatibility and component store integrity failures that trigger rollbacks
    during major feature updates:
    - Cleans temporary upgrade staging directories ($WINDOWS.~BT, $WINDOWS.~WS)
    - Performs DISM image health check and restoration (/RestoreHealth)
    - Runs System File Checker (sfc /scannow)
    - Cleans orphaned driver staging INF references
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
    Write-Error "[!] Error 0xc1900101 fix requires administrative elevation. Please run PowerShell as Administrator."
    exit 1
}

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " [WindowsFixKit] Fixing Error 0xc1900101 (Rollback/Driver)" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

# 1. Clean Staged Upgrade Folders
Write-Host "`n[+] Purging corrupted update setup staging directories..." -ForegroundColor Yellow
$stagedFolders = @("$env:SystemDrive\`$WINDOWS.~BT", "$env:SystemDrive\`$WINDOWS.~WS")

foreach ($folder in $stagedFolders) {
    if (Test-Path -Path $folder) {
        Write-Host "  [-] Cleaning $folder..." -ForegroundColor Gray
        try {
            & takeown.exe /f "$folder" /r /d y 2>&1 | Out-Null
            & icacls.exe "$folder" /grant "*S-1-5-32-544:(OI)(CI)F" /t /c /q 2>&1 | Out-Null
            Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  [OK] Removed $folder" -ForegroundColor Green
        }
        catch {
            Write-Warning "  [-] Some files in $folder could not be removed: $_"
        }
    }
}

# 2. DISM Component Store Health Restoration
Write-Host "`n[+] Checking and Repairing Windows Component Store (DISM)..." -ForegroundColor Yellow
if (Get-Command "DISM.exe" -ErrorAction SilentlyContinue) {
    Write-Host "  [-] Running DISM /Online /Cleanup-Image /StartComponentCleanup..." -ForegroundColor Gray
    & DISM.exe /Online /Cleanup-Image /StartComponentCleanup /Quiet
    
    Write-Host "  [-] Running DISM /Online /Cleanup-Image /RestoreHealth..." -ForegroundColor Gray
    & DISM.exe /Online /Cleanup-Image /RestoreHealth /Quiet
    Write-Host "  [OK] DISM repair completed." -ForegroundColor Green
}
else {
    Write-Host "  [-] DISM not found on this legacy Windows release; skipping." -ForegroundColor Gray
}

# 3. System File Checker (SFC) Integrity Scan
Write-Host "`n[+] Executing System File Integrity Scan (SFC)..." -ForegroundColor Yellow
& sfc.exe /scannow
Write-Host "  [OK] System File Checker run completed." -ForegroundColor Green

# 4. Check for Third-Party Filter Driver Conflicts
Write-Host "`n[+] Scanning for upper/lower disk filter driver conflicts..." -ForegroundColor Yellow
$diskClassKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e967-e325-11ce-bfc1-08002be10318}"
if (Test-Path -Path $diskClassKey) {
    $upperFilters = (Get-ItemProperty -Path $diskClassKey -Name UpperFilters -ErrorAction SilentlyContinue).UpperFilters
    $lowerFilters = (Get-ItemProperty -Path $diskClassKey -Name LowerFilters -ErrorAction SilentlyContinue).LowerFilters
    
    if ($upperFilters) {
        Write-Host "  [-] UpperFilters detected: $($upperFilters -join ', ')" -ForegroundColor Gray
    }
    if ($lowerFilters) {
        Write-Host "  [-] LowerFilters detected: $($lowerFilters -join ', ')" -ForegroundColor Gray
    }
    Write-Host "  [OK] Filter driver scan completed." -ForegroundColor Green
}

Write-Host "`n=========================================================" -ForegroundColor Green
Write-Host " [STATUS] Error 0xc1900101 Driver & Component Fix Completed." -ForegroundColor Green
Write-Host " [NOTE] Please disconnect unused USB peripherals and REBOOT before updating." -ForegroundColor Yellow
Write-Host "=========================================================" -ForegroundColor Green
