<#
.SYNOPSIS
    WindowsFixKit Master Full System Diagnostic Engine.
.DESCRIPTION
    Performs comprehensive hardware telemetry, operating system verification, storage health
    & SMART analysis, RAM utilization, battery capacity degradation, CPU thermal monitoring,
    disk partition thresholds, and startup bloat detection.
    Generates a color-coded console summary table and exports an HTML report to Desktop.
.EXAMPLE
    .\full_system_diagnosis.ps1
#>

[CmdletBinding()]
param(
    [string]$OutputHtmlPath = "$([Environment]::GetFolderPath('Desktop'))\WindowsFixKit-Report.html",
    [switch]$NoOpenReport
)

function Test-IsAdmin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Host "[!] Notice: Running in standard user mode. Some deep hardware counters will use standard fallbacks.`n" -ForegroundColor Yellow
}

Clear-Host -ErrorAction SilentlyContinue
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "         WindowsFixKit - Master Full System Diagnosis            " -ForegroundColor Cyan
Write-Host "       Owner: nkdhawan76 | Hardware & Subsystem Health Audit    " -ForegroundColor Cyan
Write-Host "=================================================================`n" -ForegroundColor Cyan

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { (Get-Location).Path }
if ((Split-Path -Leaf $scriptDir) -ne "scripts" -and (Test-Path (Join-Path $scriptDir "scripts"))) {
    $rootDir = $scriptDir
    $scriptDir = Join-Path $rootDir "scripts"
} else {
    $rootDir = Split-Path -Parent $scriptDir
}
$diagnosticsDir = Join-Path $scriptDir "diagnostics"
$templatePath = Join-Path $rootDir "reports\report_template.html"

if (-not (Test-Path -Path $templatePath)) {
    Write-Warning "[-] Report template not found at $templatePath"
}

# -------------------------------------------------------------------------
# Execute Individual Diagnostic Subsystems
# -------------------------------------------------------------------------
Write-Host "[1/6] Auditing Operating System & Hardware Specifications..." -ForegroundColor Yellow
$osResult = & (Join-Path $diagnosticsDir "check_os_info.ps1") -PassThru

Write-Host "`n[2/6] Auditing Physical Disks, SMART Counters & Partitions..." -ForegroundColor Yellow
$diskResult = & (Join-Path $diagnosticsDir "check_disk_health.ps1") -PassThru

Write-Host "`n[3/6] Auditing RAM Physical Modules & Buffer Allocation..." -ForegroundColor Yellow
$ramResult = & (Join-Path $diagnosticsDir "check_ram_health.ps1") -PassThru

Write-Host "`n[4/6] Auditing Battery Chemistry, Cycles & Degradation..." -ForegroundColor Yellow
$batteryResult = & (Join-Path $diagnosticsDir "check_battery_health.ps1") -PassThru

Write-Host "`n[5/6] Auditing CPU Sensor Thermals & ACPI Zones..." -ForegroundColor Yellow
$cpuResult = & (Join-Path $diagnosticsDir "check_cpu_temp.ps1") -PassThru

Write-Host "`n[6/6] Auditing Autostart Registries & Startup Bloat..." -ForegroundColor Yellow
$startupResult = & (Join-Path $diagnosticsDir "check_startup_apps.ps1") -PassThru

# -------------------------------------------------------------------------
# Compile Master Findings & Console Summary
# -------------------------------------------------------------------------
$summaryRows = [System.Collections.Generic.List[PSCustomObject]]::new()
$allRecommendations = [System.Collections.Generic.List[PSCustomObject]]::new()

# Helper badge generator
function Get-BadgeHtml {
    param([string]$Status)
    switch ($Status) {
        "Healthy"  { return '<span class="badge badge-healthy">Healthy</span>' }
        "Warning"  { return '<span class="badge badge-warning">Warning</span>' }
        "Critical" { return '<span class="badge badge-critical">Critical</span>' }
        Default    { return '<span class="badge badge-healthy">Healthy</span>' }
    }
}

# 1. Storage Summary
$storageStatus = $diskResult.Status
$summaryRows.Add([PSCustomObject]@{
    Subsystem = "Storage & Disks"
    Status    = $storageStatus
    Details   = "$($diskResult.Disks.Count) Physical Disk(s), $($diskResult.Volumes.Count) Volume(s)"
})
foreach ($rec in $diskResult.Recommendations) {
    $allRecommendations.Add([PSCustomObject]@{ Subsystem = "Storage"; Finding = $rec; FixScript = "scripts/fix_disk_errors.ps1 / fix_storage_cleanup.ps1" })
}

# 2. RAM Summary
$ramStatus = $ramResult.Status
$summaryRows.Add([PSCustomObject]@{
    Subsystem = "Memory (RAM)"
    Status    = $ramStatus
    Details   = "$($ramResult.AvailableGB) GB Free / $($ramResult.TotalGB) GB Total ($($ramResult.PercentUsed)% Used)"
})
foreach ($rec in $ramResult.Recommendations) {
    $allRecommendations.Add([PSCustomObject]@{ Subsystem = "Memory"; Finding = $rec; FixScript = "scripts/fix_ram_cache.ps1" })
}

# 3. Battery Summary
$batteryStatus = $batteryResult.Status
$summaryRows.Add([PSCustomObject]@{
    Subsystem = "Battery Health"
    Status    = $batteryStatus
    Details   = if ($batteryResult.HasBattery) { "$($batteryResult.HealthPercent)% Health ($($batteryResult.FullChargeCapMWh)/$($batteryResult.DesignCapacityMWh) mWh)" } else { "AC Powered / Desktop (No Battery)" }
})
foreach ($rec in $batteryResult.Recommendations) {
    $allRecommendations.Add([PSCustomObject]@{ Subsystem = "Battery"; Finding = $rec; FixScript = "scripts/fix_battery_optimization.ps1" })
}

# 4. CPU Thermals Summary
$cpuStatus = $cpuResult.Status
$summaryRows.Add([PSCustomObject]@{
    Subsystem = "CPU Thermals"
    Status    = $cpuStatus
    Details   = if ($cpuResult.IsWMISupported) { "Max: $($cpuResult.MaxTempCelsius) °C" } else { "OEM Sensor Locked (Use Core Temp)" }
})
foreach ($rec in $cpuResult.Recommendations) {
    $allRecommendations.Add([PSCustomObject]@{ Subsystem = "CPU Thermals"; Finding = $rec; FixScript = "scripts/fix_cpu_thermal.ps1" })
}

# 5. Startup Apps Summary
$startupStatus = $startupResult.Status
$summaryRows.Add([PSCustomObject]@{
    Subsystem = "Startup Apps"
    Status    = $startupStatus
    Details   = "$($startupResult.TotalCount) Auto-start programs detected"
})
foreach ($rec in $startupResult.Recommendations) {
    $allRecommendations.Add([PSCustomObject]@{ Subsystem = "Startup Apps"; Finding = $rec; FixScript = "scripts/fix_startup_bloat.ps1" })
}

# Determine Overall System Status
$overallSystemStatus = "Healthy"
if ($summaryRows | Where-Object { $_.Status -eq "Critical" }) {
    $overallSystemStatus = "Critical"
}
elseif ($summaryRows | Where-Object { $_.Status -eq "Warning" }) {
    $overallSystemStatus = "Warning"
}

# -------------------------------------------------------------------------
# Print Console Summary Table
# -------------------------------------------------------------------------
Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "               SYSTEM DIAGNOSIS SUMMARY TABLE                    " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

$summaryRows | Format-Table -AutoSize

if ($allRecommendations.Count -gt 0) {
    Write-Host "`n[!] ATTENTION REQUIRED: Remediation Recommendations" -ForegroundColor Yellow
    Write-Host "-----------------------------------------------------------------" -ForegroundColor Gray
    foreach ($rec in $allRecommendations) {
        Write-Host "  * [$($rec.Subsystem)] $($rec.Finding)" -ForegroundColor Yellow
        Write-Host "    -> Target Fix: $($rec.FixScript)" -ForegroundColor Cyan
    }
}
else {
    Write-Host "`n[+] EXCELLENT: All system parameters and hardware health counters are in optimal condition!" -ForegroundColor Green
}

# -------------------------------------------------------------------------
# Build and Export HTML Report
# -------------------------------------------------------------------------
if (Test-Path -Path $templatePath) {
    Write-Host "`n[+] Generating HTML Diagnostic Report at: $OutputHtmlPath ..." -ForegroundColor Yellow
    $html = Get-Content -Path $templatePath -Raw

    # 1. Interpolate Header & OS
    $html = $html.Replace("{{GENERATED_DATE}}", (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
    $html = $html.Replace("{{OVERALL_STATUS_BADGE}}", (Get-BadgeHtml -Status $overallSystemStatus))
    $html = $html.Replace("{{OS_NAME}}", [string]$osResult.OSName)
    $html = $html.Replace("{{OS_VERSION}}", [string]$osResult.OSVersion)
    $html = $html.Replace("{{OS_BUILD}}", [string]$osResult.OSBuild)
    $html = $html.Replace("{{OS_ARCH}}", [string]$osResult.OSArchitecture)
    $html = $html.Replace("{{HW_MANUFACTURER}}", [string]$osResult.Manufacturer)
    $html = $html.Replace("{{HW_MODEL}}", [string]$osResult.Model)
    $html = $html.Replace("{{SYSTEM_UPTIME}}", [string]$osResult.Uptime)

    # 2. Executive Summary Rows
    $html = $html.Replace("{{STORAGE_SUMMARY_STATUS}}", [string]$storageStatus)
    $html = $html.Replace("{{RAM_SUMMARY_STATUS}}", [string]$ramStatus)
    $html = $html.Replace("{{BATTERY_SUMMARY_STATUS}}", [string]$batteryStatus)
    $html = $html.Replace("{{CPU_SUMMARY_STATUS}}", [string]$cpuStatus)
    $html = $html.Replace("{{STARTUP_SUMMARY_STATUS}}", [string]$startupStatus)

    # 3. Storage Section HTML
    $html = $html.Replace("{{STORAGE_BADGE}}", (Get-BadgeHtml -Status $storageStatus))
    $storageDetailsHtml = ""
    foreach ($disk in $diskResult.Disks) {
        $storageDetailsHtml += @"
        <div style="margin-bottom: 12px;">
          <div class="metric-row"><span class="metric-label">Disk #$($disk.DeviceId) ($($disk.MediaType))</span><span class="metric-value">$($disk.Model) ($($disk.SizeGB) GB)</span></div>
          <div class="metric-row"><span class="metric-label">Health / Wear</span><span class="metric-value">$($disk.HealthStatus) (Wear: $($disk.WearPercent)%)</span></div>
        </div>
"@
    }
    foreach ($vol in $diskResult.Volumes) {
        $progressClass = if ($vol.PercentUsed -ge 90) { "progress-critical" } elseif ($vol.PercentUsed -ge 75) { "progress-warning" } else { "progress-healthy" }
        $storageDetailsHtml += @"
        <div style="margin-top: 10px;">
          <div class="metric-row"><span class="metric-label">Volume ($($vol.DriveLetter):)</span><span class="metric-value">$($vol.UsedGB) / $($vol.TotalGB) GB ($($vol.PercentUsed)%)</span></div>
          <div class="progress-bar-container"><div class="progress-bar $progressClass" style="width: $($vol.PercentUsed)%;"></div></div>
        </div>
"@
    }
    $html = $html.Replace("{{STORAGE_DETAILS_HTML}}", $storageDetailsHtml)

    # 4. RAM Section HTML
    $html = $html.Replace("{{RAM_BADGE}}", (Get-BadgeHtml -Status $ramStatus))
    $ramProgressClass = if ($ramResult.PercentUsed -ge 90) { "progress-critical" } elseif ($ramResult.PercentUsed -ge 75) { "progress-warning" } else { "progress-healthy" }
    $ramDetailsHtml = @"
      <div class="metric-row"><span class="metric-label">Total Installed</span><span class="metric-value">$($ramResult.TotalGB) GB</span></div>
      <div class="metric-row"><span class="metric-label">Used / Allocated</span><span class="metric-value">$($ramResult.UsedGB) GB ($($ramResult.PercentUsed)%)</span></div>
      <div class="metric-row"><span class="metric-label">Available Free</span><span class="metric-value">$($ramResult.AvailableGB) GB ($($ramResult.PercentFree)%)</span></div>
      <div class="progress-bar-container"><div class="progress-bar $ramProgressClass" style="width: $($ramResult.PercentUsed)%;"></div></div>
      <div style="margin-top: 14px; font-size: 12px; color: #9ca3af;">Installed Sticks: $($ramResult.Modules.Count) Module(s)</div>
"@
    $html = $html.Replace("{{RAM_DETAILS_HTML}}", $ramDetailsHtml)

    # 5. Battery Section HTML
    $html = $html.Replace("{{BATTERY_BADGE}}", (Get-BadgeHtml -Status $batteryStatus))
    $batteryDetailsHtml = ""
    if ($batteryResult.HasBattery) {
        $batClass = if ($batteryResult.HealthPercent -lt 60) { "progress-critical" } elseif ($batteryResult.HealthPercent -lt 80) { "progress-warning" } else { "progress-healthy" }
        $batteryDetailsHtml = @"
        <div class="metric-row"><span class="metric-label">Health Capacity</span><span class="metric-value">$($batteryResult.HealthPercent)%</span></div>
        <div class="progress-bar-container"><div class="progress-bar $batClass" style="width: $($batteryResult.HealthPercent)%;"></div></div>
        <div class="metric-row" style="margin-top: 8px;"><span class="metric-label">Design Max</span><span class="metric-value">$($batteryResult.DesignCapacityMWh) mWh</span></div>
        <div class="metric-row"><span class="metric-label">Full Charge Max</span><span class="metric-value">$($batteryResult.FullChargeCapMWh) mWh</span></div>
        <div class="metric-row"><span class="metric-label">Cycle Count</span><span class="metric-value">$($batteryResult.CycleCount)</span></div>
"@
    }
    else {
        $batteryDetailsHtml = @"
        <div class="metric-row"><span class="metric-label">Power Type</span><span class="metric-value">Direct AC Power</span></div>
        <div class="metric-row"><span class="metric-label">Battery Detected</span><span class="metric-value">No (Desktop PC / VM)</span></div>
"@
    }
    $html = $html.Replace("{{BATTERY_DETAILS_HTML}}", $batteryDetailsHtml)

    # 6. Thermal Section HTML
    $html = $html.Replace("{{THERMAL_BADGE}}", (Get-BadgeHtml -Status $cpuStatus))
    $thermalDetailsHtml = @"
      <div class="metric-row"><span class="metric-label">Processor</span><span class="metric-value" style="font-size: 11px;">$($cpuResult.CPUName)</span></div>
      <div class="metric-row"><span class="metric-label">Peak Temperature</span><span class="metric-value">$(if ($cpuResult.IsWMISupported) { "$($cpuResult.MaxTempCelsius) °C" } else { "OEM Locked" })</span></div>
      <div class="metric-row"><span class="metric-label">Sensor Status</span><span class="metric-value">$(if ($cpuResult.IsWMISupported) { "ACPI WMI Active" } else { "Use Core Temp" })</span></div>
"@
    $html = $html.Replace("{{THERMAL_DETAILS_HTML}}", $thermalDetailsHtml)

    # 7. Startup Section HTML
    $html = $html.Replace("{{STARTUP_BADGE}}", (Get-BadgeHtml -Status $startupStatus))
    $startupDetailsHtml = @"
      <div class="metric-row"><span class="metric-label">Total Launchers</span><span class="metric-value">$($startupResult.TotalCount) Items</span></div>
      <div class="metric-row"><span class="metric-label">Bloat Risk</span><span class="metric-value">$(if ($startupResult.IsBloated) { 'High (>15)' } else { 'Normal' })</span></div>
      <div class="metric-row"><span class="metric-label">Registry Run Keys</span><span class="metric-value">Scanned</span></div>
"@
    $html = $html.Replace("{{STARTUP_DETAILS_HTML}}", $startupDetailsHtml)

    # 8. Recommendations Rows HTML
    $recRowsHtml = ""
    if ($allRecommendations.Count -gt 0) {
        foreach ($rec in $allRecommendations) {
            $recRowsHtml += @"
            <tr>
              <td>$($rec.Subsystem)</td>
              <td>$($rec.Finding)</td>
              <td><code>$($rec.FixScript)</code></td>
            </tr>
"@
        }
    }
    else {
        $recRowsHtml = '<tr><td colspan="3" style="text-align: center; color: #10b981; padding: 20px;">All hardware subsystems, partitions, memory buffers, and thermals are operating in optimal status.</td></tr>'
    }
    $html = $html.Replace("{{RECOMMENDATIONS_ROWS_HTML}}", $recRowsHtml)

    # Save to disk
    Set-Content -Path $OutputHtmlPath -Value $html -Encoding UTF8
    Write-Host "  [OK] HTML Report generated successfully: $OutputHtmlPath" -ForegroundColor Green

    if (-not $NoOpenReport -and (Test-Path -Path $OutputHtmlPath)) {
        try {
            Start-Process $OutputHtmlPath -ErrorAction SilentlyContinue
        } catch {
            Write-Verbose "[-] Could not automatically open browser: $_"
        }
    }
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host " [STATUS] Full System Diagnosis Completed Successfully." -ForegroundColor Green
Write-Host "=================================================================`n" -ForegroundColor Cyan
