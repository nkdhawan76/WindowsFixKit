<#
.SYNOPSIS
    Analyzes Physical Memory (RAM) Hardware, Clock Speeds, and Real-Time Utilization.
.DESCRIPTION
    Queries Win32_PhysicalMemory for memory module manufacturers, capacities, speeds,
    and calculates active memory consumption, flagging low available RAM (<10%).
#>

[CmdletBinding()]
param(
    [switch]$PassThru
)

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " [WindowsFixKit Diagnostic] RAM Hardware & Utilization" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

$modulesInfo = [System.Collections.Generic.List[PSCustomObject]]::new()
$totalInstalledBytes = [int64]0
$availableMBytes = [double]0
$totalMBytes = [double]0
$percentFree = [double]0
$overallStatus = "Healthy"
$recommendations = [System.Collections.Generic.List[string]]::new()

# 1. Physical RAM Hardware Modules
Write-Host "`n[+] Inspecting Installed Physical Memory Sticks..." -ForegroundColor Yellow
try {
    $ramSticks = Get-CimInstance -ClassName Win32_PhysicalMemory -ErrorAction SilentlyContinue
    if ($null -eq $ramSticks) {
        $ramSticks = Get-WmiObject -Class Win32_PhysicalMemory -ErrorAction SilentlyContinue
    }

    $stickIndex = 1
    foreach ($stick in $ramSticks) {
        $capacityGB = [math]::Round($stick.Capacity / 1GB, 1)
        $manufacturer = if ($stick.Manufacturer -and $stick.Manufacturer -ne "Unknown") { $stick.Manufacturer.Trim() } else { "Generic / OEM" }
        $speedMHz = if ($stick.Speed) { "$($stick.Speed) MHz" } else { "N/A" }
        $partNumber = if ($stick.PartNumber) { $stick.PartNumber.Trim() } else { "N/A" }
        $deviceLocator = if ($stick.DeviceLocator) { $stick.DeviceLocator } else { "Slot $stickIndex" }
        
        $totalInstalledBytes += [int64]$stick.Capacity

        Write-Host "  [-] Module $deviceLocator : $capacityGB GB | $manufacturer | $speedMHz | Part: $partNumber" -ForegroundColor Gray

        $modulesInfo.Add([PSCustomObject]@{
            Slot         = $deviceLocator
            CapacityGB   = $capacityGB
            Manufacturer = $manufacturer
            Speed        = $speedMHz
            PartNumber   = $partNumber
        })
        $stickIndex++
    }
}
catch {
    Write-Warning "[-] Error reading physical RAM module information: $_"
}

# 2. System RAM Utilization
Write-Host "`n[+] Calculating Memory Allocation & Free Buffers..." -ForegroundColor Yellow
$totalMBytes = [math]::Round($totalInstalledBytes / 1MB, 0)

# Method A: Get-Counter
$counterSuccess = $false
if (Get-Command "Get-Counter" -ErrorAction SilentlyContinue) {
    try {
        $counterVal = (Get-Counter '\Memory\Available MBytes' -SampleInterval 1 -MaxSamples 1 -ErrorAction SilentlyContinue).CounterSamples[0].CookedValue
        if ($counterVal) {
            $availableMBytes = [math]::Round($counterVal, 0)
            $counterSuccess = $true
        }
    }
    catch {
        $counterSuccess = $false
    }
}

# Method B: Fallback via Win32_OperatingSystem
if (-not $counterSuccess -or $availableMBytes -le 0) {
    try {
        $osMem = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        if ($null -eq $osMem) { $osMem = Get-WmiObject Win32_OperatingSystem -ErrorAction SilentlyContinue }
        if ($osMem) {
            $availableMBytes = [math]::Round($osMem.FreePhysicalMemory / 1024, 0)
            if ($totalMBytes -le 0) {
                $totalMBytes = [math]::Round($osMem.TotalVisibleMemorySize / 1024, 0)
            }
        }
    }
    catch {
        Write-Warning "[-] Memory utilization calculation fallback encountered error: $_"
    }
}

$usedMBytes = [math]::Max([double]0, ($totalMBytes - $availableMBytes))
$percentFree = if ($totalMBytes -gt 0) { [math]::Round(($availableMBytes / $totalMBytes) * 100, 1) } else { 0 }
$percentUsed = if ($totalMBytes -gt 0) { [math]::Round(($usedMBytes / $totalMBytes) * 100, 1) } else { 0 }

$isLowMemory = $percentFree -lt 10
if ($isLowMemory) {
    $overallStatus = "Warning"
    $recommendations.Add("Available physical RAM is critically low ($percentFree% free, only $([math]::Round($availableMBytes / 1024, 1)) GB available out of $([math]::Round($totalMBytes / 1024, 1)) GB). Run fix_ram_cache.ps1 to trim standby memory pools and close runaway applications.")
}

Write-Host "  [-] Total Memory     : $([math]::Round($totalMBytes / 1024, 1)) GB ($totalMBytes MB)" -ForegroundColor Green
Write-Host "  [-] Used Memory      : $([math]::Round($usedMBytes / 1024, 1)) GB ($percentUsed%)" -ForegroundColor $(if ($isLowMemory) { "Yellow" } else { "Green" })
Write-Host "  [-] Available Memory : $([math]::Round($availableMBytes / 1024, 1)) GB ($percentFree% Free)" -ForegroundColor $(if ($isLowMemory) { "Red" } else { "Green" })

$result = [PSCustomObject]@{
    Modules         = $modulesInfo
    TotalGB         = [math]::Round($totalMBytes / 1024, 1)
    UsedGB          = [math]::Round($usedMBytes / 1024, 1)
    AvailableGB     = [math]::Round($availableMBytes / 1024, 1)
    PercentUsed     = $percentUsed
    PercentFree     = $percentFree
    Status          = $overallStatus
    Recommendations = $recommendations
}

if ($PassThru) {
    return $result
}
