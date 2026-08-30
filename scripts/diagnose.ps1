<#
.SYNOPSIS
    WindowsFixKit Diagnostic and Remediation Engine.
.DESCRIPTION
    Analyzes Windows Update error logs, validates hardware states (Wi-Fi, Bluetooth),
    tests network and DNS connectivity, matches issues in errors_db.json, and executes
    targeted automated fix scripts. Works on PowerShell 5.1 and PowerShell 7+.
.EXAMPLE
    .\diagnose.ps1
.EXAMPLE
    .\diagnose.ps1 -AutoFix -NonInteractive
#>

[CmdletBinding()]
param(
    [switch]$AutoFix = $true,
    [switch]$NonInteractive = $false,
    [switch]$ScanOnly = $false
)

# -------------------------------------------------------------------------
# 1. Elevation Verification
# -------------------------------------------------------------------------
function Test-IsAdmin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Host "`n[ERROR] Administrative Privileges Required!" -ForegroundColor Red
    Write-Host "WindowsFixKit needs full administrator rights to inspect and repair system components." -ForegroundColor Yellow
    Write-Host "`nTo run as administrator:" -ForegroundColor Cyan
    Write-Host "  1. Right-click PowerShell or Windows Terminal"
    Write-Host "  2. Select 'Run as administrator'"
    Write-Host "  3. Re-run: .\scripts\diagnose.ps1`n"
    exit 1
}

# -------------------------------------------------------------------------
# 2. Initialization & Banner
# -------------------------------------------------------------------------
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir
$errorsDbPath = Join-Path $rootDir "errors\errors_db.json"

Clear-Host -ErrorAction SilentlyContinue
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "       WindowsFixKit - System Diagnostic & Auto-Fix Engine       " -ForegroundColor Cyan
Write-Host "       Owner: nkdhawan76 | Supported: Windows 7, 8.1, 10, 11    " -ForegroundColor Cyan
Write-Host "=================================================================`n" -ForegroundColor Cyan

if (-not (Test-Path -Path $errorsDbPath)) {
    Write-Error "[!] Database file not found at $errorsDbPath. Please ensure repository integrity."
    exit 1
}

$errorsDb = Get-Content -Path $errorsDbPath -Raw | ConvertFrom-Json
$summaryReport = [System.Collections.Generic.List[PSCustomObject]]::new()
$restartRequiredOverall = $false

# -------------------------------------------------------------------------
# Helper Functions
# -------------------------------------------------------------------------
function Invoke-Remediation {
    param(
        [string]$IssueKey,
        [string]$IssueTitle,
        [string]$FixScriptRelPath,
        [bool]$RequiresRestart
    )

    $fullScriptPath = Join-Path $rootDir $FixScriptRelPath
    if (-not (Test-Path -Path $fullScriptPath)) {
        Write-Warning "  [!] Fix script not found at $fullScriptPath"
        $summaryReport.Add([PSCustomObject]@{
            "Issue Found"      = $IssueTitle
            "Fix Applied"      = "Script Missing ($FixScriptRelPath)"
            "Restart Required" = "No"
            "Status"           = "Failed"
        })
        return
    }

    if ($ScanOnly) {
        Write-Host "  [SCAN ONLY] Detected issue '$IssueTitle'. Remediation script: $FixScriptRelPath" -ForegroundColor Magenta
        $summaryReport.Add([PSCustomObject]@{
            "Issue Found"      = $IssueTitle
            "Fix Applied"      = "Skipped (Scan Only)"
            "Restart Required" = if ($RequiresRestart) { "Yes" } else { "No" }
            "Status"           = "Detected"
        })
        return
    }

    Write-Host "`n>>> Triggering Auto-Fix: $FixScriptRelPath ..." -ForegroundColor Cyan
    try {
        & $fullScriptPath -NonInteractive:$NonInteractive
        $summaryReport.Add([PSCustomObject]@{
            "Issue Found"      = $IssueTitle
            "Fix Applied"      = Split-Path $FixScriptRelPath -Leaf
            "Restart Required" = if ($RequiresRestart) { "Yes" } else { "No" }
            "Status"           = "Applied"
        })
        if ($RequiresRestart) {
            $script:restartRequiredOverall = $true
        }
    }
    catch {
        Write-Error "  [!] Error executing ${FixScriptRelPath}: $_"
        $summaryReport.Add([PSCustomObject]@{
            "Issue Found"      = $IssueTitle
            "Fix Applied"      = "Execution Error"
            "Restart Required" = "No"
            "Status"           = "Failed"
        })
    }
}

# -------------------------------------------------------------------------
# 3. Check Windows Update Logs for Error Codes
# -------------------------------------------------------------------------
Write-Host "[1/5] Analyzing Windows Update Subsystem Logs..." -ForegroundColor Yellow
$detectedErrorCodes = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

# Strategy A: Check ReportingEvents.log (Fast & universal on Win 7 - 11)
$reportingLog = "$env:SystemRoot\SoftwareDistribution\ReportingEvents.log"
if (Test-Path -Path $reportingLog) {
    Write-Host "  [-] Reading latest events from ReportingEvents.log..." -ForegroundColor Gray
    try {
        $recentLines = Get-Content -Path $reportingLog -Tail 150 -ErrorAction SilentlyContinue
        foreach ($line in $recentLines) {
            if ($line -match "0x[0-9A-Fa-f]{8}") {
                $code = $matches[0]
                # Filter out success code 0x00000000
                if ($code -ne "0x00000000" -and $code -ne "0x00000001") {
                    [void]$detectedErrorCodes.Add($code.ToLower())
                }
            }
        }
    }
    catch {
        Write-Warning "  [-] Could not read ReportingEvents.log: $_"
    }
}

# Strategy B: Windows Event Logs (System / UpdateClient)
try {
    if (Get-Command "Get-WinEvent" -ErrorAction SilentlyContinue) {
        $events = Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-WindowsUpdateClient'} -MaxEvents 30 -ErrorAction SilentlyContinue
        foreach ($evt in $events) {
            if ($evt.Message -match "0x[0-9A-Fa-f]{8}") {
                $code = $matches[0]
                if ($code -ne "0x00000000") {
                    [void]$detectedErrorCodes.Add($code.ToLower())
                }
            }
        }
    }
}
catch {
    # Silently proceed if event log query is not supported
}

# Process Detected Windows Update Error Codes
if ($detectedErrorCodes.Count -gt 0) {
    Write-Host "  [-] Found $($detectedErrorCodes.Count) recent error code(s): $($detectedErrorCodes -join ', ')" -ForegroundColor Yellow
    foreach ($errCode in $detectedErrorCodes) {
        # Check against database
        $dbEntry = $null
        foreach ($prop in $errorsDb.PSObject.Properties) {
            if ($prop.Name.ToLower() -eq $errCode.ToLower()) {
                $dbEntry = $prop.Value
                break
            }
        }

        if ($dbEntry) {
            Write-Host "  [!] Matched known issue: $($dbEntry.title) ($errCode)" -ForegroundColor Red
            if ($dbEntry.fix_script) {
                Invoke-Remediation -IssueKey $errCode -IssueTitle "$($dbEntry.title) ($errCode)" -FixScriptRelPath $dbEntry.fix_script -RequiresRestart ([bool]$dbEntry.restart_required)
            }
        }
        else {
            Write-Host "  [-] Code $errCode is not currently mapped in errors_db.json. Consider filing an issue!" -ForegroundColor Gray
        }
    }
}
else {
    Write-Host "  [OK] No active Windows Update failure codes detected in recent logs." -ForegroundColor Green
}

# -------------------------------------------------------------------------
# 4. Check Internet Connectivity (Ping 8.8.8.8)
# -------------------------------------------------------------------------
Write-Host "`n[2/5] Testing IP & Gateway Connectivity..." -ForegroundColor Yellow
$internetReachable = $false

try {
    # Check using Test-Connection or .NET Ping for universal compatibility
    $ping = New-Object System.Net.NetworkInformation.Ping
    $reply = $ping.Send("8.8.8.8", 2500)
    if ($reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
        $internetReachable = $true
    }
}
catch {
    $internetReachable = $false
}

if ($internetReachable) {
    Write-Host "  [OK] Public IP connectivity confirmed (Ping to 8.8.8.8 succeeded)." -ForegroundColor Green
}
else {
    Write-Host "  [!] Public IP unreachable (No Internet detected)." -ForegroundColor Red
    $dbEntry = $errorsDb.network_no_internet
    if ($dbEntry) {
        Invoke-Remediation -IssueKey "network_no_internet" -IssueTitle $dbEntry.title -FixScriptRelPath $dbEntry.fix_script -RequiresRestart ([bool]$dbEntry.restart_required)
    }
}

# -------------------------------------------------------------------------
# 5. Check Wi-Fi Adapter Presence & Status
# -------------------------------------------------------------------------
Write-Host "`n[3/5] Testing Wi-Fi Hardware & Adapter Status..." -ForegroundColor Yellow
$wifiIssueDetected = $false
$wifiFound = $false

if (Get-Command "Get-PnpDevice" -ErrorAction SilentlyContinue) {
    $wifiDevices = Get-PnpDevice -Class Net -ErrorAction SilentlyContinue |
        Where-Object { $_.FriendlyName -match "Wi-Fi|Wireless|802\.11|WLAN" -or $_.InstanceId -match "WLAN" }
    
    if ($wifiDevices) {
        $wifiFound = $true
        foreach ($dev in $wifiDevices) {
            if ($dev.Status -ne "OK") {
                Write-Host "  [!] Wi-Fi Device '$($dev.FriendlyName)' is in status '$($dev.Status)'." -ForegroundColor Red
                $wifiIssueDetected = $true
            }
        }
    }
}
elseif (Get-Command "Get-NetAdapter" -ErrorAction SilentlyContinue) {
    $wifiAdapters = Get-NetAdapter -ErrorAction SilentlyContinue |
        Where-Object { $_.PhysicalMediaType -match "Native 802.11|Wireless" -or $_.InterfaceDescription -match "Wireless|Wi-Fi|802\.11" }
    if ($wifiAdapters) {
        $wifiFound = $true
        foreach ($ad in $wifiAdapters) {
            if ($ad.Status -eq "Disabled") {
                Write-Host "  [!] Wi-Fi Adapter '$($ad.Name)' is currently Disabled." -ForegroundColor Red
                $wifiIssueDetected = $true
            }
        }
    }
}

# Check WLAN Service
$wlanSvc = Get-Service -Name "WlanSvc" -ErrorAction SilentlyContinue
if ($wlanSvc -and $wlanSvc.Status -ne "Running") {
    Write-Host "  [!] WLAN AutoConfig Service (WlanSvc) is $($wlanSvc.Status)." -ForegroundColor Red
    $wifiIssueDetected = $true
}

if ($wifiIssueDetected) {
    $dbEntry = $errorsDb.wifi_missing_post_update
    if ($dbEntry) {
        Invoke-Remediation -IssueKey "wifi_missing_post_update" -IssueTitle $dbEntry.title -FixScriptRelPath $dbEntry.fix_script -RequiresRestart ([bool]$dbEntry.restart_required)
    }
}
else {
    Write-Host "  [OK] Wi-Fi adapter subsystem is operational." -ForegroundColor Green
}

# -------------------------------------------------------------------------
# 6. Check Bluetooth Service Status
# -------------------------------------------------------------------------
Write-Host "`n[4/5] Testing Bluetooth Subsystem Status..." -ForegroundColor Yellow
$bluetoothIssueDetected = $false
$bthSvc = Get-Service -Name "bthserv" -ErrorAction SilentlyContinue

if ($null -eq $bthSvc) {
    Write-Host "  [-] Bluetooth service (bthserv) not installed or hardware absent." -ForegroundColor Gray
}
elseif ($bthSvc.Status -ne "Running") {
    Write-Host "  [!] Bluetooth Support Service (bthserv) is stopped/disabled ($($bthSvc.Status))." -ForegroundColor Red
    $bluetoothIssueDetected = $true
}

if ($bluetoothIssueDetected) {
    $dbEntry = $errorsDb.bluetooth_missing_post_update
    if ($dbEntry) {
        Invoke-Remediation -IssueKey "bluetooth_missing_post_update" -IssueTitle $dbEntry.title -FixScriptRelPath $dbEntry.fix_script -RequiresRestart ([bool]$dbEntry.restart_required)
    }
}
else {
    Write-Host "  [OK] Bluetooth service state is healthy." -ForegroundColor Green
}

# -------------------------------------------------------------------------
# 7. Check DNS Resolution
# -------------------------------------------------------------------------
Write-Host "`n[5/5] Testing DNS Name Resolution..." -ForegroundColor Yellow
$dnsWorking = $false

try {
    $hostEntry = [System.Net.Dns]::GetHostEntry("microsoft.com")
    if ($hostEntry.AddressList.Count -gt 0) {
        $dnsWorking = $true
    }
}
catch {
    $dnsWorking = $false
}

if ($dnsWorking) {
    Write-Host "  [OK] DNS Name resolution functional (microsoft.com resolved)." -ForegroundColor Green
}
else {
    Write-Host "  [!] DNS Name resolution failed for external domains." -ForegroundColor Red
    $dbEntry = $errorsDb.dns_not_resolving
    if ($dbEntry) {
        Invoke-Remediation -IssueKey "dns_not_resolving" -IssueTitle $dbEntry.title -FixScriptRelPath $dbEntry.fix_script -RequiresRestart ([bool]$dbEntry.restart_required)
    }
}

# -------------------------------------------------------------------------
# 8. Summary Output Table
# -------------------------------------------------------------------------
Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "                    DIAGNOSTIC SUMMARY REPORT                    " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

if ($summaryReport.Count -eq 0) {
    Write-Host "`n[+] ALL CHECKS PASSED: No Windows Update, Network, Wi-Fi, Bluetooth, or DNS errors found!" -ForegroundColor Green
}
else {
    $summaryReport | Format-Table -AutoSize
}

Write-Host "-----------------------------------------------------------------" -ForegroundColor Gray
if ($restartRequiredOverall) {
    Write-Host "[!] RESTART REQUIRED: One or more applied fixes require a system reboot to take full effect." -ForegroundColor Yellow
}
else {
    Write-Host "[OK] No system restart required at this time." -ForegroundColor Green
}
Write-Host "=================================================================`n" -ForegroundColor Cyan
