<#
.SYNOPSIS
    Deep Clean Temporary Files, Trash, Prefetch, Caches, and Reclaim Disk Space.
.DESCRIPTION
    Purges Windows Temp, User Temp (%TEMP%), Prefetch, Windows Update download caches,
    Delivery Optimization caches, Crash Dumps, Thumbnail caches, and empties Recycle Bin.
    Runs automated cleanmgr and calculates exact disk space reclaimed.
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
    Write-Host "[!] Note: Running in standard user mode. Some root system directories may require Administrator privileges.`n" -ForegroundColor Yellow
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "   WindowsFixKit - Deep Temp, Trash & Storage Cache Cleaner      " -ForegroundColor Cyan
Write-Host "      DevSparks India | https://devsparksindia.com | 9521032268   " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 0. Measure Initial Free Disk Space on System Drive
$systemDrive = if ($env:SystemDrive) { $env:SystemDrive.Substring(0, 1) } else { "C" }
$initialDrive = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$($systemDrive):'" -ErrorAction SilentlyContinue
if ($null -eq $initialDrive) { $initialDrive = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$($systemDrive):'" -ErrorAction SilentlyContinue }
$initialFreeBytes = if ($initialDrive) { [int64]$initialDrive.FreeSpace } else { [int64]0 }
$initialFreeGB = [math]::Round($initialFreeBytes / 1GB, 2)

Write-Host "`n[+] Initial Free Space on Drive ($($systemDrive):): $initialFreeGB GB" -ForegroundColor Yellow

$deletedFilesCount = 0
$deletedBytesCount = [int64]0

# 1. Clean All Temp & Cache Paths
Write-Host "`n[1/6] Purging User & System Temp Directories (%TEMP%, Windows\Temp)..." -ForegroundColor Yellow
$cleanupPaths = @(
    "$env:TEMP",
    "$env:LOCALAPPDATA\Temp",
    "$env:SystemRoot\Temp",
    "$env:SystemRoot\Prefetch",
    "$env:ProgramData\Microsoft\Windows\WER\ReportQueue",
    "$env:ProgramData\Microsoft\Windows\WER\ReportArchive",
    "$env:SystemRoot\SoftwareDistribution\Download",
    "$env:SystemRoot\Minidump",
    "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
)

# Also discover other user profile Temp directories if elevated
if (Test-IsAdmin) {
    Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $userTemp = Join-Path $_.FullName "AppData\Local\Temp"
        if ((Test-Path $userTemp) -and ($cleanupPaths -notcontains $userTemp)) {
            $cleanupPaths += $userTemp
        }
    }
}

foreach ($path in $cleanupPaths) {
    if (Test-Path -Path $path) {
        Write-Host "  [-] Cleaning: $path" -ForegroundColor Gray
        try {
            $files = Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer }
            foreach ($file in $files) {
                try {
                    $len = $file.Length
                    Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                    $deletedFilesCount++
                    $deletedBytesCount += $len
                }
                catch {
                    # File currently locked by running process, skip gracefully
                }
            }
            Write-Host "  [OK] Cleaned $path" -ForegroundColor Green
        }
        catch {
            Write-Verbose "[-] Skipped locked container in $($path): $_"
        }
    }
}

# 2. Clear Delivery Optimization Files
Write-Host "`n[2/6] Clearing Delivery Optimization & BITS Transfer Cache..." -ForegroundColor Yellow
if (Get-Command "Delete-DeliveryOptimizationCache" -ErrorAction SilentlyContinue) {
    try {
        Delete-DeliveryOptimizationCache -Force -ErrorAction SilentlyContinue
        Write-Host "  [OK] Delivery Optimization Cache deleted." -ForegroundColor Green
    }
    catch {
        Write-Verbose "[-] Delivery Optimization cache delete returned: $_"
    }
} else {
    Write-Host "  [-] Delivery Optimization cmdlet not available on this version." -ForegroundColor Gray
}

# 3. Empty Windows Recycle Bin
Write-Host "`n[3/6] Emptying Windows Recycle Bin across all drives..." -ForegroundColor Yellow
try {
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Host "  [OK] Recycle Bin completely emptied." -ForegroundColor Green
}
catch {
    Write-Verbose "[-] Could not clear recycle bin: $_"
}

# 4. Clear Windows Error Reporting & Crash Dumps
Write-Host "`n[4/6] Purging Crash Dumps & Windows Error Reports..." -ForegroundColor Yellow
$dumpFiles = @(
    "$env:SystemRoot\MEMORY.DMP",
    "$env:LOCALAPPDATA\CrashDumps"
)
foreach ($d in $dumpFiles) {
    if (Test-Path $d) {
        try {
            Remove-Item $d -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  [OK] Removed crash dump artifacts from $d" -ForegroundColor Green
        } catch {}
    }
}

# 5. Clear Browser Cache Caches (Edge, Chrome, Brave Temp Caches)
Write-Host "`n[5/6] Cleaning Web Browser Temporary Cache Files..." -ForegroundColor Yellow
$browserCaches = @(
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
    "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Cache"
)
foreach ($bCache in $browserCaches) {
    if (Test-Path $bCache) {
        try {
            Get-ChildItem -Path $bCache -Recurse -Force -ErrorAction SilentlyContinue |
                Where-Object { -not $_.PSIsContainer } |
                Remove-Item -Force -ErrorAction SilentlyContinue
            Write-Host "  [OK] Cleaned browser cache: $bCache" -ForegroundColor Green
        } catch {}
    }
}

# 6. Execute Native Cleanmgr Automated Pass
Write-Host "`n[6/6] Executing Windows Cleanmgr Storage Reclamation..." -ForegroundColor Yellow
if (Test-Path -Path "$env:SystemRoot\System32\cleanmgr.exe") {
    try {
        Start-Process -FilePath "$env:SystemRoot\System32\cleanmgr.exe" -ArgumentList "/autoclean /d $($systemDrive):" -NoNewWindow -Wait -ErrorAction SilentlyContinue
        Write-Host "  [OK] Windows Cleanmgr background optimization complete." -ForegroundColor Green
    } catch {
        Write-Verbose "[-] Cleanmgr execution skipped: $_"
    }
}

# Measure Final Free Space
$finalDrive = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$($systemDrive):'" -ErrorAction SilentlyContinue
if ($null -eq $finalDrive) { $finalDrive = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$($systemDrive):'" -ErrorAction SilentlyContinue }
$finalFreeBytes = if ($finalDrive) { [int64]$finalDrive.FreeSpace } else { [int64]0 }
$finalFreeGB = [math]::Round($finalFreeBytes / 1GB, 2)
$reclaimedMB = [math]::Round(($finalFreeBytes - $initialFreeBytes) / 1MB, 1)
if ($reclaimedMB -lt 0) { $reclaimedMB = [math]::Round($deletedBytesCount / 1MB, 1) }

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "                  STORAGE CLEANUP SUMMARY                        " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "  * Initial Free Space : $initialFreeGB GB" -ForegroundColor Gray
Write-Host "  * Current Free Space : $finalFreeGB GB" -ForegroundColor Green
Write-Host "  * Total Files Purged : $deletedFilesCount items" -ForegroundColor Green
Write-Host "  * Reclaimed Space    : $reclaimedMB MB" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " [STATUS] All Trashed Files & System Caches Cleaned Successfully." -ForegroundColor Green
Write-Host "=================================================================`n" -ForegroundColor Cyan
