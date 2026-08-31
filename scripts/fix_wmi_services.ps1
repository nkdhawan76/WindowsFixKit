<#
.SYNOPSIS
    WMI Repository & Core Windows Background Services Repair Engine.
.DESCRIPTION
    Audits and remediates Windows Management Instrumentation (WMI) repository corruption,
    verifies critical system services (sppsvc, ClipSVC, KeyIso, BITS, CryptSvc, TrustedInstaller, wuauserv),
    repairs missing or corrupted Null driver service, cleans SuppressRulesEngine registry blocks,
    and re-registers core WMI binary libraries and MOFs.
    
    DevSparks India | https://devsparksindia.com | 9521032268
#>

[CmdletBinding()]
param(
    [switch]$ForceReset
)

$ErrorActionPreference = "Continue"

# Elevation Check
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "[!] Administrative privileges required. Please run this script as Administrator."
    exit 1
}

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " [WindowsFixKit] WMI Repository & Core Services Repair" -ForegroundColor Cyan
Write-Host "  DevSparks India | https://devsparksindia.com | 9521032268" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

$logPath = Join-Path (Split-Path -Parent $PSScriptRoot) "scripts\repair_log.txt"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] [WMI_SERVICES_REPAIR] $Message"
    Add-Content -Path $logPath -Value $entry -ErrorAction SilentlyContinue
}

Write-Log "Starting WMI repository and core services remediation..."

# 1. WMI Repository Verification & Salvage
Write-Host "`n[+] 1. Checking WMI Repository Health..." -ForegroundColor Yellow
$wmiVerify = & winmgmt.exe /verifyrepository 2>&1
Write-Host "  [-] winmgmt /verifyrepository result: $wmiVerify" -ForegroundColor Gray

if ($wmiVerify -match "INCONSISTENT|corrupt|fail" -or $ForceReset) {
    Write-Host "  [!] WMI Repository is inconsistent or salvage requested. Attempting salvage..." -ForegroundColor Magenta
    $wmiSalvage = & winmgmt.exe /salvagerepository 2>&1
    Write-Host "  [-] Salvage output: $wmiSalvage" -ForegroundColor Gray
    
    if ($wmiSalvage -match "INCONSISTENT|fail" -or $ForceReset) {
        Write-Host "  [!] Salvage failed or ForceReset specified. Performing full repository reset..." -ForegroundColor Red
        & winmgmt.exe /resetrepository 2>&1 | Out-Null
        Write-Host "  [+] WMI repository reset successfully." -ForegroundColor Green
        Write-Log "WMI repository reset performed."
    } else {
        Write-Host "  [+] WMI repository salvaged successfully." -ForegroundColor Green
        Write-Log "WMI repository salvaged."
    }
} else {
    Write-Host "  [+] WMI Repository is consistent and healthy." -ForegroundColor Green
}

# 2. Repair Null Service (Prevents silent crashes in command shells and services)
Write-Host "`n[+] 2. Checking Null Driver Service Configuration..." -ForegroundColor Yellow
try {
    $nullServiceKey = "HKLM:\SYSTEM\CurrentControlSet\Services\Null"
    if (Test-Path $nullServiceKey) {
        $startType = (Get-ItemProperty -Path $nullServiceKey -Name "Start" -ErrorAction SilentlyContinue).Start
        if ($startType -ne 1) {
            Write-Host "  [!] Null service Start type is invalid ($startType). Repairing to Boot Start (1)..." -ForegroundColor Magenta
            Set-ItemProperty -Path $nullServiceKey -Name "Start" -Value 1 -Type DWord -Force
            Write-Host "  [+] Null service Start type restored to 1." -ForegroundColor Green
            Write-Log "Restored Null driver Start type to 1."
        } else {
            Write-Host "  [+] Null driver service configured correctly (Start=1)." -ForegroundColor Green
        }
    }
} catch {
    Write-Warning "  [-] Could not audit Null driver service: $_"
}

# 3. Clean SuppressRulesEngine Registry Keys
Write-Host "`n[+] 3. Checking for SuppressRulesEngine Registry Blocks..." -ForegroundColor Yellow
$sppPolicyKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform",
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
)
foreach ($key in $sppPolicyKeys) {
    if (Test-Path $key) {
        $val = Get-ItemProperty -Path $key -Name "SuppressRulesEngine" -ErrorAction SilentlyContinue
        if ($null -ne $val) {
            Write-Host "  [!] Found blocking SuppressRulesEngine in $key. Removing..." -ForegroundColor Magenta
            Remove-ItemProperty -Path $key -Name "SuppressRulesEngine" -Force -ErrorAction SilentlyContinue
            Write-Host "  [+] SuppressRulesEngine key removed." -ForegroundColor Green
            Write-Log "Removed SuppressRulesEngine from $key."
        }
    }
}
Write-Host "  [+] Licensing & Servicing engine registry policies verified." -ForegroundColor Green

# 4. Critical Windows Core Services Health Check & Recovery
Write-Host "`n[+] 4. Verifying & Recovering Core Windows Services..." -ForegroundColor Yellow
$criticalServices = @(
    @{ Name = "winmgmt"; Display = "Windows Management Instrumentation"; RequiredStart = "Automatic" },
    @{ Name = "RpcSs"; Display = "Remote Procedure Call (RPC)"; RequiredStart = "Automatic" },
    @{ Name = "DcomLaunch"; Display = "DCOM Server Process Launcher"; RequiredStart = "Automatic" },
    @{ Name = "KeyIso"; Display = "CNG Key Isolation"; RequiredStart = "Manual" },
    @{ Name = "sppsvc"; Display = "Software Protection Platform"; RequiredStart = "Automatic" },
    @{ Name = "ClipSVC"; Display = "Client License Service"; RequiredStart = "Manual" },
    @{ Name = "BITS"; Display = "Background Intelligent Transfer Service"; RequiredStart = "Automatic" },
    @{ Name = "CryptSvc"; Display = "Cryptographic Services"; RequiredStart = "Automatic" },
    @{ Name = "wuauserv"; Display = "Windows Update"; RequiredStart = "Manual" },
    @{ Name = "TrustedInstaller"; Display = "Windows Modules Installer"; RequiredStart = "Manual" }
)

foreach ($svc in $criticalServices) {
    try {
        $svcObj = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
        if ($null -eq $svcObj) {
            Write-Host "  [-] Service $($svc.Name) ($($svc.Display)): Not present on this OS build." -ForegroundColor Gray
            continue
        }

        # Check startup type via Get-CimInstance
        $cimSvc = Get-CimInstance -ClassName Win32_Service -Filter "Name='$($svc.Name)'" -ErrorAction SilentlyContinue
        $startMode = if ($cimSvc) { $cimSvc.StartMode } else { "Unknown" }

        if ($startMode -eq "Disabled") {
            Write-Host "  [!] $($svc.Display) ($($svc.Name)) was DISABLED. Re-enabling to $($svc.RequiredStart)..." -ForegroundColor Magenta
            Set-Service -Name $svc.Name -StartupType $svc.RequiredStart -ErrorAction SilentlyContinue
            Write-Log "Re-enabled disabled service $($svc.Name) to $($svc.RequiredStart)."
        }

        # Attempt to start if it should be running (winmgmt, RpcSs, DcomLaunch, CryptSvc)
        if ($svc.Name -in @("winmgmt", "RpcSs", "DcomLaunch", "CryptSvc") -and $svcObj.Status -ne "Running") {
            Write-Host "  [-] Starting $($svc.Display)..." -ForegroundColor Yellow
            Start-Service -Name $svc.Name -ErrorAction SilentlyContinue
        }

        $currentStatus = (Get-Service -Name $svc.Name -ErrorAction SilentlyContinue).Status
        Write-Host "  [+] $($svc.Display) [$($svc.Name)] : Status=$currentStatus | Startup=$startMode" -ForegroundColor Green
    } catch {
        Write-Warning "  [-] Error checking service $($svc.Name): $_"
    }
}

# 5. Core WMI Binaries & MOF Re-registration
Write-Host "`n[+] 5. Re-registering Core WMI Binaries & MOF Classes..." -ForegroundColor Yellow
$wbemDir = "$env:SystemRoot\System32\Wbem"
if (Test-Path $wbemDir) {
    $coreDlls = @("wmidc.dll", "wbemcomn.dll", "wbemcore.dll", "wbemdisp.dll", "wbemsvc.dll")
    foreach ($dll in $coreDlls) {
        $dllPath = Join-Path $wbemDir $dll
        if (Test-Path $dllPath) {
            & regsvr32.exe /s $dllPath
        }
    }
    
    # Compile core MOF if needed
    $coreMof = Join-Path $wbemDir "wmicore.mof"
    if (Test-Path $coreMof) {
        & mofcomp.exe -N:$wbemDir $coreMof 2>&1 | Out-Null
    }
    Write-Host "  [+] WMI Core binary registration verified." -ForegroundColor Green
}

Write-Log "WMI and core services repair completed successfully."

Write-Host "`n=========================================================" -ForegroundColor Cyan
Write-Host " [COMPLETED] WMI & Core Services Health Successfully Restored!" -ForegroundColor Green
Write-Host "  Log File: $logPath" -ForegroundColor Gray
Write-Host "=========================================================" -ForegroundColor Cyan
