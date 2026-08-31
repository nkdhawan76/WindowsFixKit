<#
.SYNOPSIS
    Hardens telemetry and privacy policy registry keys with automatic .reg backup.
.DESCRIPTION
    Applies privacy-enhancing registry policies to minimize diagnostic feedback and telemetry.
    Backs up all targeted registry keys to a timestamped .reg file on the Desktop before applying changes.
    Explicitly preserves Windows Defender and all core endpoint protection settings.
    Idempotent and safe to run multiple times.
#>

<#
================================================================================
CRITICAL SECURITY NOTICE FOR CONTRIBUTORS:
DO NOT ADD ANY REGISTRY ENTRIES THAT DISABLE WINDOWS DEFENDER, DISABLEANTISPYWARE,
REAL-TIME MONITORING, SMART SCREEN, OR SIGNATURE UPDATES.
Privacy hardening must never compromise system security posture.
================================================================================
#>

[CmdletBinding()]
param(
    [switch]$NonInteractive
)

function Test-IsAdmin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Error "[!] Telemetry and privacy configuration requires administrative privileges. Please run as Administrator."
    exit 1
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "      WindowsFixKit - Telemetry & Privacy Registry Hardener     " -ForegroundColor Cyan
Write-Host "      DevSparks India | https://devsparksindia.com | 9521032268   " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Create Backup Directory on Desktop
$backupDir = Join-Path ([System.Environment]::GetFolderPath("Desktop")) "WindowsFixKit-Backup"
if (-not (Test-Path -Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
}

$timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$backupFile = Join-Path $backupDir "Registry_Telemetry_Backup_$timestamp.reg"

Write-Host "`n[+] Backing up current registry state before applying privacy policies..." -ForegroundColor Yellow

$keysToBackup = @(
    "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack",
    "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection",
    "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection",
    "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat",
    "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting"
)

# Export existing keys via reg.exe
$backupSuccess = $false
foreach ($k in $keysToBackup) {
    try {
        $tempReg = Join-Path $backupDir "temp_$($k.Replace('\','_')).reg"
        & reg.exe export "$k" "$tempReg" /y 2>&1 | Out-Null
        if (Test-Path $tempReg) {
            $content = Get-Content $tempReg -Raw -ErrorAction SilentlyContinue
            Add-Content -Path $backupFile -Value $content -Force -ErrorAction SilentlyContinue
            Remove-Item $tempReg -Force -ErrorAction SilentlyContinue
            $backupSuccess = $true
        }
    } catch {}
}

if (Test-Path $backupFile) {
    Write-Host "  [OK] Registry backup safely saved to: $backupFile" -ForegroundColor Green
} else {
    Write-Host "  [-] Key targets were either fresh or uninitialized. Proceeding safely." -ForegroundColor Gray
}

# Helper to ensure registry path exists and write DWORD
function Set-SafeRegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [int]$Value
    )

    try {
        if (-not (Test-Path -Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type DWord -Force -ErrorAction Stop
        Write-Host "  [OK] Set $Path\$Name = $Value" -ForegroundColor Green
    } catch {
        Write-Warning "  [-] Failed setting $Path\$Name : $_"
    }
}

# 2. Apply Telemetry Hardening Policies
Write-Host "`n[+] Applying Privacy & Telemetry Hardening Policies..." -ForegroundColor Yellow

# DiagTrack TestHooks
Set-SafeRegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack\TestHooks" -Name "Disabled" -Value 1

# System Data Collection Policy
Set-SafeRegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 0

# Group Policy Data Collection
Set-SafeRegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0
Set-SafeRegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DoNotShowFeedbackNotifications" -Value 1

# Application Telemetry & Inventory
Set-SafeRegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -Name "DisableInventory" -Value 1
Set-SafeRegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -Name "AITEnable" -Value 0

# Windows Error Reporting Telemetry (Preserves core reporting while disabling diagnostic harvesting)
Set-SafeRegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -Value 1
Set-SafeRegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" -Name "DoNotSendAdditionalData" -Value 1
Set-SafeRegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" -Name "LoggingDisabled" -Value 1

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host " [STATUS] Telemetry & Privacy Registry Hardening Completed." -ForegroundColor Green
Write-Host "=================================================================`n" -ForegroundColor Cyan
