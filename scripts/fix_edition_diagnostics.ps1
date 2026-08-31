<#
.SYNOPSIS
    Windows Edition Upgrade Readiness & Servicing State Diagnostic Engine.
.DESCRIPTION
    Audits current Windows OS edition, available target editions for in-place upgrade,
    detects pending system reboot flags that block servicing operations, and checks for
    virtualized environments (Windows Sandbox / Hyper-V).
    
    DevSparks India | https://devsparksindia.com | 9521032268
#>

[CmdletBinding()]
param(
    [switch]$ClearPendingRebootFlags
)

$ErrorActionPreference = "Continue"

# Elevation Check
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "[!] Administrative privileges required. Please run this script as Administrator."
    exit 1
}

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " [WindowsFixKit] Windows Edition & Servicing Diagnostics" -ForegroundColor Cyan
Write-Host "  DevSparks India | https://devsparksindia.com | 9521032268" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

$logPath = Join-Path (Split-Path -Parent $PSScriptRoot) "scripts\repair_log.txt"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] [EDITION_DIAG] $Message"
    Add-Content -Path $logPath -Value $entry -ErrorAction SilentlyContinue
}

Write-Log "Starting Windows edition and servicing diagnostics..."

# 1. OS & Edition Information via CIM
Write-Host "`n[+] 1. Auditing Current Windows Operating System & Edition..." -ForegroundColor Yellow
try {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    Write-Host "  [-] Caption        : $($os.Caption)" -ForegroundColor Green
    Write-Host "  [-] OS Version     : $($os.Version) (Build $($os.BuildNumber))" -ForegroundColor White
    Write-Host "  [-] Architecture   : $($os.OSArchitecture)" -ForegroundColor White
    Write-Host "  [-] System Directory: $($os.WindowsDirectory)" -ForegroundColor White
    Write-Host "  [-] Install Date   : $($os.InstallDate)" -ForegroundColor White
    
    # Check for Evaluation Edition
    if ($os.Caption -match "Evaluation|Eval") {
        Write-Host "  [!] Operating System is an EVALUATION edition." -ForegroundColor Magenta
    }
} catch {
    Write-Warning "  [-] Failed to query Win32_OperatingSystem: $_"
}

# 2. Virtualization / Windows Sandbox Detection
Write-Host "`n[+] 2. Checking Virtualization & Windows Sandbox Status..." -ForegroundColor Yellow
$isSandbox = $false
try {
    $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
    if ($cs.Model -match "Virtual|VMware|VirtualBox|KVM|Hyper-V" -or (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Containers")) {
        $isSandbox = $true
        Write-Host "  [-] Virtualized / Container environment detected ($($cs.Model))." -ForegroundColor Magenta
    } else {
        Write-Host "  [+] Physical hardware host detected." -ForegroundColor Green
    }
} catch {
    Write-Warning "  [-] Error querying computer system: $_"
}

# 3. Query Target Upgrade Editions via DISM
Write-Host "`n[+] 3. Checking Available Target Upgrade Editions via DISM..." -ForegroundColor Yellow
try {
    $dismEditions = & dism.exe /Online /Get-TargetEditions 2>&1
    $targetLines = $dismEditions | Where-Object { $_ -match "Target Edition :" }
    if ($targetLines) {
        Write-Host "  [+] Supported In-Place Target Editions:" -ForegroundColor Green
        foreach ($line in $targetLines) {
            Write-Host "      $line" -ForegroundColor White
        }
    } else {
        Write-Host "  [-] No alternative upgrade target editions exposed on this image." -ForegroundColor Gray
    }
} catch {
    Write-Warning "  [-] DISM target editions query failed: $_"
}

# 4. Audit Pending Reboot Flags
Write-Host "`n[+] 4. Auditing Pending Reboot Flags (CBS & Windows Update)..." -ForegroundColor Yellow
$rebootFlags = @()

$cbsKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
if (Test-Path $cbsKey) {
    $rebootFlags += "Component Based Servicing (RebootPending)"
}

$wuKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
if (Test-Path $wuKey) {
    $rebootFlags += "Windows Update (RebootRequired)"
}

$sessionKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
$pendingFileRename = (Get-ItemProperty -Path $sessionKey -Name "PendingFileRenameOperations" -ErrorAction SilentlyContinue).PendingFileRenameOperations
if ($pendingFileRename) {
    $rebootFlags += "PendingFileRenameOperations ($($pendingFileRename.Count) items)"
}

if ($rebootFlags.Count -gt 0) {
    Write-Host "  [!] System has PENDING REBOOT flags active:" -ForegroundColor Magenta
    foreach ($flag in $rebootFlags) {
        Write-Host "      [-] $flag" -ForegroundColor Yellow
    }
    Write-Host "  [-] Notice: Active reboot flags can prevent DISM component servicing and driver updates." -ForegroundColor Gray
    
    if ($ClearPendingRebootFlags) {
        Write-Host "  [-] Clearing pending reboot flags as requested..." -ForegroundColor Yellow
        Remove-Item -Path $cbsKey -Force -ErrorAction SilentlyContinue | Out-Null
        Remove-Item -Path $wuKey -Force -ErrorAction SilentlyContinue | Out-Null
        Write-Host "  [+] Servicing pending reboot flags cleared." -ForegroundColor Green
        Write-Log "Cleared pending reboot flags."
    }
} else {
    Write-Host "  [+] No pending reboot flags found. Servicing and DISM engine ready." -ForegroundColor Green
}

Write-Log "Edition and servicing diagnostic finished."

Write-Host "`n=========================================================" -ForegroundColor Cyan
Write-Host " [COMPLETED] Windows Edition & Servicing Diagnostics Done!" -ForegroundColor Green
Write-Host "  Log File: $logPath" -ForegroundColor Gray
Write-Host "=========================================================" -ForegroundColor Cyan
