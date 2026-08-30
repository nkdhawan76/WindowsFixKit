<#
.SYNOPSIS
    Queries CPU Thermal Zone Temperatures via ACPI WMI Provider.
.DESCRIPTION
    Extracts CPU temperature in Celsius from root/wmi:MSAcpi_ThermalZoneTemperature.
    Provides clear fallback guidance (Core Temp / HWMonitor) if OEM BIOS firmware locks
    direct ACPI temperature polling.
#>

[CmdletBinding()]
param(
    [switch]$PassThru
)

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " [WindowsFixKit Diagnostic] CPU Thermals & Temperatures" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

$thermalZones = [System.Collections.Generic.List[PSCustomObject]]::new()
$wmiSupported = $false
$maxTempC = 0.0
$overallStatus = "Healthy"
$recommendations = [System.Collections.Generic.List[string]]::new()
$cpuName = "Generic CPU"

# 1. Query CPU Details
try {
    $cpuObj = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $cpuObj) { $cpuObj = Get-WmiObject Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1 }
    if ($cpuObj) {
        $cpuName = $cpuObj.Name.Trim()
        $cores = $cpuObj.NumberOfCores
        $logicalProc = $cpuObj.NumberOfLogicalProcessors
        Write-Host "`n[+] Processor: $cpuName ($cores Cores / $logicalProc Threads)" -ForegroundColor Yellow
    }
}
catch {
    Write-Warning "[-] Error identifying CPU processor: $_"
}

# 2. Query ACPI Thermal Zones
Write-Host "[+] Querying ACPI Thermal Sensors via root/wmi..." -ForegroundColor Yellow

try {
    $zones = Get-CimInstance -Namespace "root/wmi" -ClassName "MSAcpi_ThermalZoneTemperature" -ErrorAction SilentlyContinue
    if ($null -eq $zones) {
        $zones = Get-WmiObject -Namespace "root/wmi" -Class "MSAcpi_ThermalZoneTemperature" -ErrorAction SilentlyContinue
    }

    if ($zones) {
        $wmiSupported = $true
        foreach ($zone in $zones) {
            # Temp is stored in tenths of Kelvin: C = (K / 10) - 273.15
            $rawKelvin10 = $zone.CurrentTemperature
            $tempC = [math]::Round((($rawKelvin10 / 10.0) - 273.15), 1)
            $zoneName = if ($zone.InstanceName) { $zone.InstanceName } else { "ThermalZone" }
            
            if ($tempC -gt $maxTempC) {
                $maxTempC = $tempC
            }

            $isHot = $tempC -ge 80.0
            $isCritical = $tempC -ge 90.0

            Write-Host "  [-] Zone: $zoneName -> $tempC °C" -ForegroundColor $(if ($isCritical) { "Red" } elseif ($isHot) { "Yellow" } else { "Green" })

            $thermalZones.Add([PSCustomObject]@{
                ZoneName     = $zoneName
                TempCelsius  = $tempC
                IsHot        = $isHot
                IsCritical   = $isCritical
            })
        }
    }
}
catch {
    $wmiSupported = $false
}

if ($wmiSupported -and $thermalZones.Count -gt 0) {
    if ($maxTempC -ge 90.0) {
        $overallStatus = "Critical"
        $recommendations.Add("CPU peak temperature is CRITICALLY HIGH ($maxTempC °C). Check thermal paste, fan operation, and run fix_cpu_thermal.ps1 to prevent hardware throttling.")
    }
    elseif ($maxTempC -ge 80.0) {
        $overallStatus = "Warning"
        $recommendations.Add("CPU peak temperature is elevated ($maxTempC °C). Ensure heatsink air vents are clear and run fix_cpu_thermal.ps1.")
    }
    else {
        Write-Host "  [OK] CPU temperatures are within normal operating thresholds (Peak: $maxTempC °C)." -ForegroundColor Green
    }
}
else {
    Write-Host "  [-] ACPI Thermal Polling: Not exposed by OEM BIOS on this motherboard." -ForegroundColor Gray
    Write-Host "  [-] Recommendation: Use dedicated hardware sensor tools (Core Temp / HWMonitor / HWiNFO) for direct ring-0 diode readings." -ForegroundColor Cyan
    $maxTempC = 0.0
}

$result = [PSCustomObject]@{
    CPUName         = $cpuName
    IsWMISupported  = $wmiSupported
    MaxTempCelsius  = $maxTempC
    ThermalZones    = $thermalZones
    Status          = $overallStatus
    Recommendations = $recommendations
}

if ($PassThru) {
    return $result
}
