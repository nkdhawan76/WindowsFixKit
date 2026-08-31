<#
.SYNOPSIS
    Windows Script Host (WSH) & System Environment Variables Health Engine.
.DESCRIPTION
    Audits and remediates Windows Script Host (WSH) disabled state in registry,
    verifies and restores essential system directories in the PATH environment variable
    (%SystemRoot%, %SystemRoot%\System32, %SystemRoot%\System32\Wbem, WindowsPowerShell),
    and unblocks downloaded scripts by removing Zone.Identifier streams (Mark of the Web).
    
    DevSparks India | https://devsparksindia.com | 9521032268
#>

[CmdletBinding()]
param(
    [switch]$UnblockAllScripts
)

$ErrorActionPreference = "Continue"

# Elevation Check
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "[!] Administrative privileges required. Please run this script as Administrator."
    exit 1
}

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " [WindowsFixKit] Windows Script Host & Environment Fixer" -ForegroundColor Cyan
Write-Host "  DevSparks India | https://devsparksindia.com | 9521032268" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

$logPath = Join-Path (Split-Path -Parent $PSScriptRoot) "scripts\repair_log.txt"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] [WSH_ENV_FIX] $Message"
    Add-Content -Path $logPath -Value $entry -ErrorAction SilentlyContinue
}

Write-Log "Starting Windows Script Host and PATH environment audit..."

# 1. Audit & Re-enable Windows Script Host (WSH)
Write-Host "`n[+] 1. Checking Windows Script Host (WSH) Registry Configuration..." -ForegroundColor Yellow
$wshKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows Script Host\Settings",
    "HKCU:\Software\Microsoft\Windows Script Host\Settings"
)

foreach ($wshKey in $wshKeys) {
    if (-not (Test-Path $wshKey)) {
        New-Item -Path $wshKey -Force -ErrorAction SilentlyContinue | Out-Null
    }
    
    $enabledVal = (Get-ItemProperty -Path $wshKey -Name "Enabled" -ErrorAction SilentlyContinue).Enabled
    if ($null -ne $enabledVal -and $enabledVal -eq 0) {
        Write-Host "  [!] WSH is currently DISABLED in $wshKey. Restoring Enabled=1..." -ForegroundColor Magenta
        Set-ItemProperty -Path $wshKey -Name "Enabled" -Value 1 -Type DWord -Force
        Write-Host "  [+] WSH re-enabled in $wshKey." -ForegroundColor Green
        Write-Log "Re-enabled WSH in $wshKey (set Enabled=1)."
    } else {
        # Ensure default enabled state
        Set-ItemProperty -Path $wshKey -Name "Enabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Write-Host "  [+] WSH is enabled and functional in $wshKey." -ForegroundColor Green
    }
}

# 2. Audit & Repair System PATH Environment Variables
Write-Host "`n[+] 2. Checking System PATH Environment Variable Integrity..." -ForegroundColor Yellow
$sysEnvKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
$currentPath = (Get-ItemProperty -Path $sysEnvKey -Name "Path" -ErrorAction SilentlyContinue).Path

if ($currentPath) {
    $pathEntries = $currentPath -split ';' | Where-Object { $_ -match '\S' }
    $requiredPaths = @(
        "$env:SystemRoot\system32",
        "$env:SystemRoot",
        "$env:SystemRoot\System32\Wbem",
        "$env:SystemRoot\System32\WindowsPowerShell\v1.0\"
    )

    $missingPaths = @()
    foreach ($req in $requiredPaths) {
        $normalizedReq = $req.TrimEnd('\').ToLower()
        $found = $pathEntries | Where-Object { $_.TrimEnd('\').ToLower() -eq $normalizedReq }
        if (-not $found) {
            $missingPaths += $req
        }
    }

    if ($missingPaths.Count -gt 0) {
        Write-Host "  [!] Missing essential system directories in System PATH: $($missingPaths -join '; ')" -ForegroundColor Magenta
        Write-Host "  [-] Appending missing directories to System PATH..." -ForegroundColor Yellow
        $newPath = ($pathEntries + $missingPaths) -join ';'
        Set-ItemProperty -Path $sysEnvKey -Name "Path" -Value $newPath -Type ExpandString -Force
        $env:Path = $newPath
        Write-Host "  [+] System PATH updated with required core directories." -ForegroundColor Green
        Write-Log "Repaired System PATH by adding missing: $($missingPaths -join '; ')"
    } else {
        Write-Host "  [+] All essential system directories (%SystemRoot%, System32, Wbem, PowerShell) present in PATH." -ForegroundColor Green
    }
} else {
    Write-Warning "  [-] Could not read System PATH from registry."
}

# 3. Clean Zone.Identifier Streams (Unblock Scripts)
Write-Host "`n[+] 3. Removing Zone.Identifier (Mark of the Web) Streams..." -ForegroundColor Yellow
$rootDir = Split-Path -Parent $PSScriptRoot
try {
    $scriptFiles = Get-ChildItem -Path $rootDir -Include *.ps1,*.bat,*.cmd -Recurse -File -ErrorAction SilentlyContinue
    $unblockedCount = 0
    foreach ($file in $scriptFiles) {
        try {
            Unblock-File -Path $file.FullName -ErrorAction SilentlyContinue
            $unblockedCount++
        } catch {
            # Skip if file in use or no permission
        }
    }
    Write-Host "  [+] Unblocked $unblockedCount script file(s) across WindowsFixKit repository." -ForegroundColor Green
    Write-Log "Unblocked $unblockedCount script files (removed Zone.Identifier)."
} catch {
    Write-Warning "  [-] Error during file unblocking: $_"
}

Write-Host "`n=========================================================" -ForegroundColor Cyan
Write-Host " [COMPLETED] Windows Script Host & Environment Fixed!" -ForegroundColor Green
Write-Host "  Log File: $logPath" -ForegroundColor Gray
Write-Host "=========================================================" -ForegroundColor Cyan
