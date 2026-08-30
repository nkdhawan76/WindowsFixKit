<#
.SYNOPSIS
    Generates and analyzes Windows Battery Health, Capacity Loss, and Cycle Count.
.DESCRIPTION
    Executes 'powercfg /batteryreport', parses Design Capacity against Full Charge Capacity,
    and flags severely degraded batteries (<60% original design capacity).
    Gracefully identifies Desktop / AC-powered PCs with no battery.
#>

[CmdletBinding()]
param(
    [switch]$PassThru
)

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " [WindowsFixKit Diagnostic] Battery Health & Degradation" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

$tempReportPath = "$env:TEMP\battery_report_$([guid]::NewGuid().ToString('N')).html"
$hasBattery = $false
$designCapacity = 0
$fullChargeCapacity = 0
$healthPercent = 0
$cycleCount = "N/A"
$overallStatus = "Healthy"
$recommendations = [System.Collections.Generic.List[string]]::new()

# 1. Quick check for Battery WMI/CIM instance
$batteryWmi = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
if ($null -eq $batteryWmi) {
    $batteryWmi = Get-WmiObject -Class Win32_Battery -ErrorAction SilentlyContinue
}

# 2. Run powercfg /batteryreport
Write-Host "`n[+] Generating hardware battery telemetry via powercfg..." -ForegroundColor Yellow

$powercfgOutput = & powercfg.exe /batteryreport /output "$tempReportPath" 2>&1

if (Test-Path -Path $tempReportPath) {
    try {
        $htmlContent = Get-Content -Path $tempReportPath -Raw -ErrorAction SilentlyContinue
        
        # Regex extraction of Design Capacity and Full Charge Capacity
        if ($htmlContent -match "DESIGN CAPACITY\s*</td>\s*<td[^>]*>\s*([\d,]+)\s*mWh") {
            $designCapacity = [int]($matches[1] -replace "[, ]", "")
            $hasBattery = $true
        }
        if ($htmlContent -match "FULL CHARGE CAPACITY\s*</td>\s*<td[^>]*>\s*([\d,]+)\s*mWh") {
            $fullChargeCapacity = [int]($matches[1] -replace "[, ]", "")
            $hasBattery = $true
        }
        if ($htmlContent -match "CYCLE COUNT\s*</td>\s*<td[^>]*>\s*([\d,]+)\s*</td>") {
            $cycleCount = $matches[1].Trim()
        }

        # Calculate health %
        if ($designCapacity -gt 0 -and $fullChargeCapacity -gt 0) {
            $healthPercent = [math]::Round(($fullChargeCapacity / $designCapacity) * 100, 1)
        }
    }
    catch {
        Write-Warning "[-] Error parsing battery report HTML: $_"
    }
    finally {
        Remove-Item -Path $tempReportPath -Force -ErrorAction SilentlyContinue
    }
}

if ($hasBattery -and $designCapacity -gt 0) {
    $isDegraded = $healthPercent -lt 60
    if ($isDegraded) {
        $overallStatus = "Warning"
        $recommendations.Add("Battery maximum capacity has degraded to $healthPercent% of original design ($fullChargeCapacity mWh out of $designCapacity mWh). Run fix_battery_optimization.ps1 and consider replacing the battery hardware.")
    }

    Write-Host "  [-] Battery Present    : Yes" -ForegroundColor Green
    Write-Host "  [-] Design Capacity    : $designCapacity mWh" -ForegroundColor Gray
    Write-Host "  [-] Full Charge Cap    : $fullChargeCapacity mWh" -ForegroundColor Gray
    Write-Host "  [-] Health Percentage  : $healthPercent%" -ForegroundColor $(if ($isDegraded) { "Yellow" } else { "Green" })
    Write-Host "  [-] Cycle Count        : $cycleCount" -ForegroundColor Gray
    Write-Host "  [-] Battery Status     : $(if ($isDegraded) { 'Degraded (<60%)' } else { 'Healthy' })" -ForegroundColor $(if ($isDegraded) { "Yellow" } else { "Green" })
}
else {
    Write-Host "  [-] No internal battery detected (Desktop / Virtual Machine / AC Powered)." -ForegroundColor Green
    $overallStatus = "Healthy"
    $healthPercent = 100
}

$result = [PSCustomObject]@{
    HasBattery          = $hasBattery
    DesignCapacityMWh   = $designCapacity
    FullChargeCapMWh    = $fullChargeCapacity
    HealthPercent       = $healthPercent
    CycleCount          = $cycleCount
    Status              = $overallStatus
    Recommendations     = $recommendations
}

if ($PassThru) {
    return $result
}
