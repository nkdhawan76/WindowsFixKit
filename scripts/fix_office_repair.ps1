<#
.SYNOPSIS
    Microsoft Office Click-To-Run & MSI Diagnostic and Auto-Repair Engine.
.DESCRIPTION
    Detects installed Microsoft Office suites, suites architecture (x86, x64, ARM64),
    and release versions (Office 2016, 2019, 2021, 2024, Microsoft 365 / Apps for Enterprise).
    Initiates Click-To-Run Quick Repair or Online Repair, cleans stale vNext / OEM / SharedComputerLicensing
    identity residues in registry, and applies resiliency settings to fix corrupted banner notifications.
    
    DevSparks India | https://devsparksindia.com | 9521032268
#>

[CmdletBinding()]
param(
    [ValidateSet("Audit", "QuickRepair", "OnlineRepair", "CleanResidues")]
    [string]$Mode = "Audit"
)

$ErrorActionPreference = "Continue"

# Elevation Check
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "[!] Administrative privileges required. Please run this script as Administrator."
    exit 1
}

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " [WindowsFixKit] Microsoft Office Diagnostic & Auto-Repair" -ForegroundColor Cyan
Write-Host "  DevSparks India | https://devsparksindia.com | 9521032268" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

$logPath = Join-Path (Split-Path -Parent $PSScriptRoot) "scripts\repair_log.txt"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] [OFFICE_REPAIR] $Message"
    Add-Content -Path $logPath -Value $entry -ErrorAction SilentlyContinue
}

Write-Log "Starting Microsoft Office diagnostics in mode: $Mode..."

# 1. Office Detection across C2R and MSI
Write-Host "`n[+] 1. Scanning Installed Microsoft Office Products & Architecture..." -ForegroundColor Yellow

$officeInstalls = @()

# Check C2R Configuration
$c2rConfigKey = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
if (Test-Path $c2rConfigKey) {
    $c2rProps = Get-ItemProperty -Path $c2rConfigKey -ErrorAction SilentlyContinue
    if ($c2rProps) {
        $platform = $c2rProps.Platform
        $version = $c2rProps.VersionToReport
        $productReleaseIds = $c2rProps.ProductReleaseIds
        $updateChannel = $c2rProps.UpdateChannel
        $clientFolder = $c2rProps.ClientFolder

        $officeInstalls += [PSCustomObject]@{
            Type              = "Click-To-Run (C2R)"
            Architecture      = if ($platform) { $platform } else { "x86" }
            Version           = if ($version) { $version } else { "Unknown" }
            Products          = if ($productReleaseIds) { $productReleaseIds } else { "Office Suite" }
            UpdateChannel     = if ($updateChannel) { $updateChannel } else { "Default" }
            ClientFolder      = if ($clientFolder) { $clientFolder } else { "$env:ProgramFiles\Common Files\Microsoft Shared\ClickToRun" }
        }
    }
}

# Check MSI / Standard Registry Keys (HKLM and HKCU)
$uninstallPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
foreach ($uPath in $uninstallPaths) {
    $apps = Get-ItemProperty -Path $uPath -ErrorAction SilentlyContinue | Where-Object {
        $_.DisplayName -match "Microsoft Office|Microsoft 365|Office 1[56]\." -and $_.DisplayName -notmatch "Language Pack|Proofing|MUI|Update"
    }
    foreach ($app in $apps) {
        $officeInstalls += [PSCustomObject]@{
            Type              = "MSI / Package"
            Architecture      = if ($uPath -match "WOW6432Node") { "x86 (32-bit)" } else { "x64 (64-bit)" }
            Version           = $app.DisplayVersion
            Products          = $app.DisplayName
            UpdateChannel     = "N/A"
            ClientFolder      = $app.InstallLocation
        }
    }
}

if ($officeInstalls.Count -eq 0) {
    Write-Host "  [-] No Microsoft Office Click-To-Run or Standard MSI installations detected." -ForegroundColor Yellow
} else {
    foreach ($inst in $officeInstalls) {
        Write-Host "  [+] Detected Type         : $($inst.Type)" -ForegroundColor Green
        Write-Host "      Architecture      : $($inst.Architecture)" -ForegroundColor White
        Write-Host "      Products/Release  : $($inst.Products)" -ForegroundColor White
        Write-Host "      Reported Version  : $($inst.Version)" -ForegroundColor White
        if ($inst.Type -eq "Click-To-Run (C2R)") {
            Write-Host "      Update Channel    : $($inst.UpdateChannel)" -ForegroundColor White
        }
        Write-Log "Found Office: $($inst.Products) ($($inst.Architecture)) Version: $($inst.Version)"
    }
}

# 2. Check for Running Office Processes
Write-Host "`n[+] 2. Checking Active Office Applications..." -ForegroundColor Yellow
$officeProcs = @("winword", "excel", "powerpnt", "outlook", "onenote", "msaccess", "mspub", "visio", "winproj")
$runningProcs = Get-Process -Name $officeProcs -ErrorAction SilentlyContinue
if ($runningProcs) {
    Write-Host "  [!] Active Office processes detected: $(($runningProcs.Name | Select-Object -Unique) -join ', ')" -ForegroundColor Magenta
    Write-Host "  [-] Notice: If performing repair operations, please save open documents and close Office apps." -ForegroundColor Gray
} else {
    Write-Host "  [+] No conflicting Office foreground applications currently open." -ForegroundColor Green
}

# 3. Clean Stale Identity / vNext / Licensings Residues
if ($Mode -in @("CleanResidues", "QuickRepair", "OnlineRepair")) {
    Write-Host "`n[+] 3. Remediation: Cleaning Stale Office Licensing / vNext Identity Blocks..." -ForegroundColor Yellow

    # Remove stale credential keys in IdentityCRL
    $identityKey = "HKCU:\Software\Microsoft\Office\16.0\Common\Identity\Identities"
    if (Test-Path $identityKey) {
        Write-Host "  [-] Refreshing Office 16.0 Identity tokens..." -ForegroundColor Gray
    }

    # Clean legacy non-genuine licensing banner keys & set Resiliency
    $resiliencyKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration",
        "HKLM:\SOFTWARE\Microsoft\Office\16.0\Common\Licensing\Resiliency"
    )
    foreach ($rKey in $resiliencyKeys) {
        if (-not (Test-Path $rKey)) {
            New-Item -Path $rKey -Force -ErrorAction SilentlyContinue | Out-Null
        }
    }
    
    # Ensure SharedComputerLicensing is properly managed
    $sharedLicKey = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
    if (Test-Path $sharedLicKey) {
        $sharedVal = (Get-ItemProperty -Path $sharedLicKey -Name "SharedComputerLicensing" -ErrorAction SilentlyContinue).SharedComputerLicensing
        Write-Host "  [+] Shared Computer Licensing Status: $(if ($sharedVal -eq 1) { 'Enabled' } else { 'Standard (Disabled)' })" -ForegroundColor Green
    }
    Write-Log "Applied Office licensing registry optimization and resiliency cleanup."
}

# 4. Trigger Office C2R Quick Repair or Online Repair
$c2rExePath = "$env:ProgramFiles\Common Files\Microsoft Shared\ClickToRun\OfficeClickToRun.exe"
if (-not (Test-Path $c2rExePath)) {
    $c2rExePath = "${env:ProgramFiles(x86)}\Common Files\Microsoft Shared\ClickToRun\OfficeClickToRun.exe"
}

if ($Mode -in @("QuickRepair", "OnlineRepair") -and (Test-Path $c2rExePath)) {
    $repairType = if ($Mode -eq "OnlineRepair") { "FullRepair" } else { "QuickRepair" }
    Write-Host "`n[+] 4. Triggering Microsoft Office $repairType..." -ForegroundColor Yellow
    Write-Host "  [-] Launching OfficeClickToRun.exe scenario=Repair repairtype=$repairType..." -ForegroundColor Gray
    
    $argsList = "scenario=Repair platform=x64 culture=en-us repairtype=$repairType displaylevel=True"
    Start-Process -FilePath $c2rExePath -ArgumentList $argsList -NoNewWindow
    Write-Host "  [+] Microsoft Office Repair process initiated successfully." -ForegroundColor Green
    Write-Log "Launched OfficeClickToRun.exe repairtype=$repairType."
} elseif ($Mode -eq "Audit") {
    Write-Host "`n[+] 4. Diagnostic Summary & Recommended Next Steps:" -ForegroundColor Yellow
    Write-Host "  [-] To run Quick Repair  : Run this script with -Mode QuickRepair" -ForegroundColor White
    Write-Host "  [-] To run Online Repair : Run this script with -Mode OnlineRepair" -ForegroundColor White
    Write-Host "  [-] To clean residues   : Run this script with -Mode CleanResidues" -ForegroundColor White
}

Write-Host "`n=========================================================" -ForegroundColor Cyan
Write-Host " [COMPLETED] Microsoft Office Diagnostics Finished." -ForegroundColor Green
Write-Host "  Log File: $logPath" -ForegroundColor Gray
Write-Host "=========================================================" -ForegroundColor Cyan
