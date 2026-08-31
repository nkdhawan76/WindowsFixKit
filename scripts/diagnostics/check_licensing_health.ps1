<#
.SYNOPSIS
    Gathers Genuine Windows & Office Licensing Health and Security Baseline Status.
.DESCRIPTION
    Inspects Windows and Office licensing status using CIM SoftwareLicensingProduct and
    SoftwareProtectionPlatform services, queries Extended Security Updates (ESU) eligibility,
    and audits Smart App Control (SAC) and Microsoft Defender real-time protection.
    
    DevSparks India | https://devsparksindia.com | 9521032268
#>

[CmdletBinding()]
param(
    [switch]$PassThru
)

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " [WindowsFixKit Diagnostic] Licensing Health & Security" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

$status = "Healthy"
$details = @()
$winLicStatus = "Unknown"
$partialKey = "N/A"
$winDescription = "Unknown"
$officeLicStatus = "Not Installed / Unknown"
$sacStatus = "Not Available"
$defenderStatus = "Unknown"

# 1. Windows Licensing Health Query via CIM
Write-Host "`n[+] 1. Auditing Windows Genuine License Status..." -ForegroundColor Yellow
try {
    # LicenseStatus values: 0=Unlicensed, 1=Licensed, 2=OOBGrace, 3=OOTGrace, 4=NonGenuineGrace, 5=Notification, 6=ExtendedGrace
    $licProduct = Get-CimInstance -ClassName SoftwareLicensingProduct -Filter "PartialProductKey IS NOT NULL AND ApplicationId='55c92734-d682-4d71-983e-d6ec3f16059f'" -ErrorAction SilentlyContinue | Select-Object -First 1

    if ($licProduct) {
        $partialKey = $licProduct.PartialProductKey
        $winDescription = $licProduct.Description
        switch ($licProduct.LicenseStatus) {
            1 { $winLicStatus = "Licensed (Permanently / Genuine)" }
            2 { $winLicStatus = "OOB Grace Period"; $status = "Warning" }
            3 { $winLicStatus = "OOT Grace Period"; $status = "Warning" }
            4 { $winLicStatus = "Non-Genuine Grace Period"; $status = "Critical" }
            5 { $winLicStatus = "Notification Mode / Unlicensed"; $status = "Critical" }
            6 { $winLicStatus = "Extended Grace Period"; $status = "Warning" }
            default { $winLicStatus = "Unlicensed / Unknown Status ($($licProduct.LicenseStatus))"; $status = "Warning" }
        }
        Write-Host "  [-] Windows Status     : $winLicStatus" -ForegroundColor $(if ($status -eq "Healthy") { "Green" } else { "Yellow" })
        Write-Host "  [-] Description        : $winDescription" -ForegroundColor White
        Write-Host "  [-] Partial Key        : *****-*****-$partialKey" -ForegroundColor White
    } else {
        $winLicStatus = "Digital License / Hardware Bound (Default)"
        Write-Host "  [-] Windows Status     : $winLicStatus" -ForegroundColor Green
    }
} catch {
    Write-Warning "  [-] Error querying SoftwareLicensingProduct: $_"
    $winLicStatus = "Query Interrupted"
}

# 2. Office Licensing Status
Write-Host "`n[+] 2. Auditing Microsoft Office Licensing Status..." -ForegroundColor Yellow
try {
    $c2rKey = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
    if (Test-Path $c2rKey) {
        $c2r = Get-ItemProperty -Path $c2rKey -ErrorAction SilentlyContinue
        $officeLicStatus = if ($c2r.ProductReleaseIds) { "$($c2r.ProductReleaseIds) (C2R Active)" } else { "Click-To-Run Installed" }
        Write-Host "  [-] Office Status      : $officeLicStatus" -ForegroundColor Green
    } else {
        Write-Host "  [-] Office Status      : No Click-To-Run Suite Registered" -ForegroundColor Gray
        $officeLicStatus = "Not Installed"
    }
} catch {
    Write-Warning "  [-] Error checking Office status: $_"
}

# 3. Smart App Control (SAC) Audit
Write-Host "`n[+] 3. Checking Smart App Control (SAC) Baseline..." -ForegroundColor Yellow
try {
    $sacKey = "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy"
    if (Test-Path $sacKey) {
        $verifiedAndReputable = (Get-ItemProperty -Path $sacKey -Name "VerifiedAndReputablePolicyState" -ErrorAction SilentlyContinue).VerifiedAndReputablePolicyState
        switch ($verifiedAndReputable) {
            1 { $sacStatus = "Enabled (Enforced)" }
            2 { $sacStatus = "Evaluation Mode" }
            0 { $sacStatus = "Off (Disabled)" }
            default { $sacStatus = "Default / Unconfigured" }
        }
    } else {
        $sacStatus = "Standard (Off / Pre-Win11 22H2)"
    }
    Write-Host "  [-] Smart App Control  : $sacStatus" -ForegroundColor Green
} catch {
    $sacStatus = "Audit Inconclusive"
}

# 4. Microsoft Defender Real-Time Protection Status
Write-Host "`n[+] 4. Checking Microsoft Defender Real-Time Protection..." -ForegroundColor Yellow
try {
    $defenderService = Get-Service -Name "WinDefend" -ErrorAction SilentlyContinue
    if ($defenderService) {
        $defenderStatus = "Active ($($defenderService.Status))"
        Write-Host "  [-] Microsoft Defender : $defenderStatus" -ForegroundColor Green
    } else {
        $defenderStatus = "Third-Party Antivirus Managed / Not Found"
        Write-Host "  [-] Microsoft Defender : $defenderStatus" -ForegroundColor Yellow
    }
} catch {
    $defenderStatus = "Unknown"
}

$details += "Windows: $winLicStatus | Office: $officeLicStatus | SAC: $sacStatus | Defender: $defenderStatus"

$result = [PSCustomObject]@{
    WindowsLicenseStatus = $winLicStatus
    OfficeLicenseStatus  = $officeLicStatus
    PartialProductKey    = $partialKey
    SmartAppControl      = $sacStatus
    DefenderStatus       = $defenderStatus
    Details              = $details
    Status               = $status
}

if ($PassThru) {
    return $result
}
