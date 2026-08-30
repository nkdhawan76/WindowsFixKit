<#
.SYNOPSIS
    Evaluates Physical Storage Health, SMART Counters, Media Types, and Partition Capacities.
.DESCRIPTION
    Inspects physical drives (HDD/SSD/NVMe), queries wear level, temperature, read error counts,
    and checks partition free space thresholds (>90% usage flagged).
#>

[CmdletBinding()]
param(
    [switch]$PassThru
)

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " [WindowsFixKit Diagnostic] Storage Health & Capacities" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

$disksInfo = [System.Collections.Generic.List[PSCustomObject]]::new()
$volumesInfo = [System.Collections.Generic.List[PSCustomObject]]::new()
$overallStatus = "Healthy"
$recommendations = [System.Collections.Generic.List[string]]::new()

# 1. Physical Disks & SMART Telemetry
Write-Host "`n[+] Checking Physical Storage Disks & SMART Status..." -ForegroundColor Yellow

if (Get-Command "Get-PhysicalDisk" -ErrorAction SilentlyContinue) {
    try {
        $physicalDisks = Get-PhysicalDisk -ErrorAction SilentlyContinue
        foreach ($disk in $physicalDisks) {
            $mediaType = if ($disk.MediaType) { $disk.MediaType } else { "Unspecified/NVMe" }
            $healthStatus = $disk.HealthStatus
            $opStatus = $disk.OperationalStatus -join ', '
            $sizeGB = [math]::Round($disk.Size / 1GB, 1)
            $wearPercent = 0
            $tempC = "N/A"
            $readErrors = 0
            $uncorrectedErrors = 0

            # Query Storage Reliability Counter where supported
            if (Get-Command "Get-StorageReliabilityCounter" -ErrorAction SilentlyContinue) {
                try {
                    $reliability = $disk | Get-StorageReliabilityCounter -ErrorAction SilentlyContinue
                    if ($reliability) {
                        $wearPercent = if ($null -ne $reliability.Wear) { $reliability.Wear } else { 0 }
                        $tempC = if ($null -ne $reliability.Temperature) { "$($reliability.Temperature) °C" } else { "N/A" }
                        $readErrors = if ($null -ne $reliability.ReadErrorsTotal) { $reliability.ReadErrorsTotal } else { 0 }
                        $uncorrectedErrors = if ($null -ne $reliability.ReadErrorsUncorrected) { $reliability.ReadErrorsUncorrected } else { 0 }
                    }
                }
                catch {
                    Write-Verbose "[-] Storage reliability counter not exposed by disk driver."
                }
            }

            $diskIsHealthy = $true
            if ($healthStatus -ne "Healthy" -or $wearPercent -gt 80 -or $uncorrectedErrors -gt 0) {
                $diskIsHealthy = $false
                $overallStatus = "Critical"
                $recommendations.Add("Physical Disk '$($disk.FriendlyName)' exhibits health degradation (Health: $healthStatus, Wear: $wearPercent%, Uncorrected Read Errors: $uncorrectedErrors). Run fix_disk_errors.ps1 and backup data immediately.")
            }

            Write-Host "  [-] Disk #$($disk.DeviceId): $($disk.FriendlyName) [$mediaType, $sizeGB GB]" -ForegroundColor Gray
            Write-Host "      Health Status: $healthStatus | Operational: $opStatus" -ForegroundColor $(if ($diskIsHealthy) { "Green" } else { "Red" })
            Write-Host "      Wear Level: $wearPercent% | Temp: $tempC | Read Errors: $readErrors (Uncorrected: $uncorrectedErrors)" -ForegroundColor Gray

            $disksInfo.Add([PSCustomObject]@{
                DeviceId          = $disk.DeviceId
                Model             = $disk.FriendlyName
                MediaType         = $mediaType
                SizeGB            = $sizeGB
                HealthStatus      = $healthStatus
                OperationalStatus = $opStatus
                WearPercent       = $wearPercent
                Temperature       = $tempC
                ReadErrorsTotal   = $readErrors
                ReadErrorsUncorrected = $uncorrectedErrors
                IsHealthy         = $diskIsHealthy
            })
        }
    }
    catch {
        Write-Warning "[-] Error querying Get-PhysicalDisk: $_"
    }
}
else {
    Write-Host "  [-] Get-PhysicalDisk cmdlet not supported on this Windows version, skipping advanced SMART check." -ForegroundColor Gray
    # Legacy Win32_DiskDrive Fallback
    try {
        $legacyDisks = Get-CimInstance Win32_DiskDrive -ErrorAction SilentlyContinue
        if ($null -eq $legacyDisks) { $legacyDisks = Get-WmiObject Win32_DiskDrive -ErrorAction SilentlyContinue }
        foreach ($ldisk in $legacyDisks) {
            $sizeGB = [math]::Round($ldisk.Size / 1GB, 1)
            $status = $ldisk.Status
            Write-Host "  [-] Disk: $($ldisk.Model) [$sizeGB GB] - Status: $status" -ForegroundColor $(if ($status -eq "OK") { "Green" } else { "Red" })
            $disksInfo.Add([PSCustomObject]@{
                DeviceId          = $ldisk.Index
                Model             = $ldisk.Model
                MediaType         = "Disk Drive"
                SizeGB            = $sizeGB
                HealthStatus      = $status
                OperationalStatus = $status
                WearPercent       = 0
                Temperature       = "N/A"
                ReadErrorsTotal   = 0
                ReadErrorsUncorrected = 0
                IsHealthy         = ($status -eq "OK")
            })
        }
    }
    catch {
        Write-Warning "[-] Fallback disk query error: $_"
    }
}

# 2. Partitions & Volume Capacity
Write-Host "`n[+] Checking Logical Partitions and Free Space..." -ForegroundColor Yellow
$drives = Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue | Where-Object { $_.Used -gt 0 }

foreach ($drive in $drives) {
    $totalGB = [math]::Round(($drive.Used + $drive.Free) / 1GB, 1)
    $usedGB = [math]::Round($drive.Used / 1GB, 1)
    $freeGB = [math]::Round($drive.Free / 1GB, 1)
    $percentUsed = if ($totalGB -gt 0) { [math]::Round(($usedGB / $totalGB) * 100, 1) } else { 0 }
    
    $isSpaceWarning = $percentUsed -ge 90
    if ($isSpaceWarning) {
        if ($overallStatus -ne "Critical") { $overallStatus = "Warning" }
        $recommendations.Add("Partition $($drive.Name): is $percentUsed% full ($freeGB GB free remaining). Run fix_storage_cleanup.ps1 to purge temporary files and system caches.")
    }

    Write-Host "  [-] Partition $($drive.Name): $usedGB / $totalGB GB used ($percentUsed%) - $freeGB GB Free" -ForegroundColor $(if ($isSpaceWarning) { "Yellow" } else { "Green" })

    $volumesInfo.Add([PSCustomObject]@{
        DriveLetter = $drive.Name
        TotalGB     = $totalGB
        UsedGB      = $usedGB
        FreeGB      = $freeGB
        PercentUsed = $percentUsed
        IsWarning   = $isSpaceWarning
    })
}

$result = [PSCustomObject]@{
    Disks           = $disksInfo
    Volumes         = $volumesInfo
    Status          = $overallStatus
    Recommendations = $recommendations
}

if ($PassThru) {
    return $result
}
