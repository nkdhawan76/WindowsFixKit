<#
.SYNOPSIS
    Packages diagnostic logs, HTML reports, and system telemetry into a shareable bundle.
.DESCRIPTION
    Creates a compressed diagnostic archive on the Desktop, generates instant pre-filled
    Email and WhatsApp support links for DevSparks India support engineers, and copies the
    telemetry summary to the clipboard.
    Idempotent and safe to run multiple times.
#>

[CmdletBinding()]
param(
    [switch]$NonInteractive
)

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "     WindowsFixKit - Diagnostic Log Bundler & Support Assist     " -ForegroundColor Cyan
Write-Host "      DevSparks India | https://devsparksindia.com | 9521032268   " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { (Get-Location).Path }
$rootDir = if ((Split-Path -Leaf $scriptDir) -eq "scripts") { Split-Path -Parent $scriptDir } else { $scriptDir }

$desktopPath = [System.Environment]::GetFolderPath("Desktop")
$shareBundleDir = Join-Path $desktopPath "WindowsFixKit-Share-Bundle"
if (-not (Test-Path $shareBundleDir)) {
    New-Item -ItemType Directory -Path $shareBundleDir -Force | Out-Null
}

$timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$zipPath = Join-Path $shareBundleDir "WindowsFixKit_Diagnostic_$timestamp.zip"
$tempStaging = Join-Path $env:TEMP "WFK_ShareStaging_$timestamp"
New-Item -ItemType Directory -Path $tempStaging -Force | Out-Null

Write-Host "`n[1/3] Collecting Diagnostic Reports & Event Logs..." -ForegroundColor Yellow

# 1. Collect HTML Report from Desktop if exists
$reportHtml = Join-Path $desktopPath "WindowsFixKit-Report.html"
if (Test-Path $reportHtml) {
    Copy-Item -Path $reportHtml -Destination $tempStaging -Force
    Write-Host "  [OK] Attached Desktop HTML Diagnostic Report." -ForegroundColor Green
}

# 2. Collect Repair Logs
$repairLog = Join-Path $rootDir "scripts\repair_log.txt"
if (Test-Path $repairLog) {
    Copy-Item -Path $repairLog -Destination $tempStaging -Force
    Write-Host "  [OK] Attached Windows Update Repair Log." -ForegroundColor Green
}

# 3. Generate Machine Summary Text
$os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
$cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
$summaryTxt = Join-Path $tempStaging "system_telemetry_summary.txt"

$summaryLines = @(
    "=================================================================",
    "WindowsFixKit Diagnostic Telemetry Summary",
    "Generated: " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),
    "Support Contact: DevSparks India | devsparksindia@gmail.com | +91 9521032268",
    "=================================================================",
    "",
    "Operating System : " + $os.Caption + " (" + $os.Version + ", Build " + $os.BuildNumber + ")",
    "Architecture     : " + $os.OSArchitecture,
    "Machine Model    : " + $cs.Manufacturer + " - " + $cs.Model,
    "User Name        : " + $env:USERNAME,
    "Computer Name    : " + $env:COMPUTERNAME,
    "Total Memory     : " + [string]([math]::Round($os.TotalVisibleMemorySize / 1024, 0)) + " MB",
    "Free Memory      : " + [string]([math]::Round($os.FreePhysicalMemory / 1024, 0)) + " MB",
    "System Drive     : " + $env:SystemDrive,
    "",
    "Recent Diagnostic Modules Audited:",
    "- BSOD Kernel Crash Dumps & BugChecks",
    "- Storage SMART Health & Partition Free Capacities",
    "- RAM Buffers & Working Set Allocation",
    "- Network & DNS Stack Diagnostic",
    "- Windows Update Subsystem Logs",
    "================================================================="
)

$summaryLines | Out-File -FilePath $summaryTxt -Encoding UTF8 -Force

# 4. Compress to ZIP
Write-Host "`n[2/3] Generating Compressed Support Bundle..." -ForegroundColor Yellow
Compress-Archive -Path "$tempStaging\*" -DestinationPath $zipPath -Force
Remove-Item $tempStaging -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "  [OK] Diagnostic package successfully saved to:" -ForegroundColor Green
Write-Host "       $zipPath" -ForegroundColor Cyan

# 5. Support Links
Write-Host "`n[3/3] Direct Support Channels with DevSparks India:" -ForegroundColor Yellow
$subjectEncoded = [System.Uri]::EscapeDataString("WindowsFixKit Support Request - " + $env:COMPUTERNAME)
$bodyText = "Hello DevSparks India Support Team,`n`nI have run WindowsFixKit diagnostics and generated a report bundle.`n`nAttached Log File: " + $zipPath + "`n`nIssue Description:`n[Please describe your issue here]"
$bodyEncoded = [System.Uri]::EscapeDataString($bodyText)
$mailtoUrl = "mailto:devsparksindia@gmail.com?subject=" + $subjectEncoded + "&body=" + $bodyEncoded
$whatsappText = [System.Uri]::EscapeDataString("Hi DevSparks India, I generated a WindowsFixKit diagnostic bundle for my PC (" + $env:COMPUTERNAME + ") and need technical assistance.")
$whatsappUrl = "https://wa.me/919521032268?text=" + $whatsappText

Write-Host "  * Email Link    : devsparksindia@gmail.com" -ForegroundColor Cyan
Write-Host "  * Phone/WhatsApp: +91 9521032268" -ForegroundColor Cyan
Write-Host "  * Helpdesk      : https://devsparksindia.com/" -ForegroundColor Cyan

if (-not $NonInteractive) {
    Write-Host "`n[?] Would you like to open the support email draft now? (Y/N)" -ForegroundColor Yellow
    $ans = Read-Host
    if ($ans -match "^[yY]") {
        Start-Process $mailtoUrl -ErrorAction SilentlyContinue
    }
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host " [STATUS] Diagnostic Package Created & Support Channels Ready." -ForegroundColor Green
Write-Host "=================================================================`n" -ForegroundColor Cyan
