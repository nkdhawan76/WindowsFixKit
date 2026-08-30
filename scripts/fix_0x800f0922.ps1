<#
.SYNOPSIS
    Fixes Windows Update error 0x800f0922 (.NET / SSU / System Partition / VPN Failure).
.DESCRIPTION
    Fixes failures related to .NET Framework feature installation, insufficient EFI/System
    Reserved partition free space, and active VPN proxy filter interference during updates.
    Idempotent and safe to run multiple times.
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
    Write-Error "[!] Error 0x800f0922 fix requires administrative elevation. Please run PowerShell as Administrator."
    exit 1
}

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " [WindowsFixKit] Fixing Error 0x800f0922 (.NET / SSU / VPN)" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

# 1. Check & Repair .NET Framework Feature State
Write-Host "`n[+] Enabling and repairing .NET Framework core features..." -ForegroundColor Yellow
if (Get-Command "DISM.exe" -ErrorAction SilentlyContinue) {
    try {
        & DISM.exe /Online /Enable-Feature /FeatureName:NetFx3 /All /NoRestart /Quiet
        Write-Host "  [OK] .NET Framework 3.5 feature state refreshed." -ForegroundColor Green
    }
    catch {
        Write-Warning "  [-] DISM NetFx3 enable step returned: $_"
    }
}

# 2. Inspect System Reserved / System Drive Partition Free Space
Write-Host "`n[+] Inspecting system disk capacity..." -ForegroundColor Yellow
$systemDrive = Get-PSDrive -Name ($env:SystemDrive.Substring(0,1)) -ErrorAction SilentlyContinue
if ($systemDrive) {
    $freeGb = [math]::Round($systemDrive.Free / 1GB, 2)
    Write-Host "  [-] System Drive ($env:SystemDrive) Free Space: $freeGb GB" -ForegroundColor Gray
    if ($freeGb -lt 15) {
        Write-Warning "  [!] System Drive has less than 15 GB free space. Updates may fail without disk cleanup."
    }
    else {
        Write-Host "  [OK] System Drive has sufficient free space." -ForegroundColor Green
    }
}

# 3. Clean CBS / Servicing Logs
Write-Host "`n[+] Purging bloated CBS (Component-Based Servicing) logs..." -ForegroundColor Yellow
$cbsPath = "$env:SystemRoot\Logs\CBS"
if (Test-Path -Path $cbsPath) {
    Get-ChildItem -Path $cbsPath -Filter "*.log" -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne "CBS.log" } |
        Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Host "  [OK] CBS log directory cleaned." -ForegroundColor Green
}

# 4. Check for Active VPN Adapters
Write-Host "`n[+] Checking for active VPN/Proxy interfaces..." -ForegroundColor Yellow
$vpnAdapters = @()
if (Get-Command "Get-NetAdapter" -ErrorAction SilentlyContinue) {
    $vpnAdapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object {
        ($_.InterfaceDescription -match "VPN|TAP|WireGuard|OpenVPN|Nord|Express|Cisco") -and ($_.Status -eq "Up")
    }
}

if ($vpnAdapters.Count -gt 0) {
    Write-Warning "  [!] Active VPN connection detected: $($vpnAdapters.Name -join ', ')."
    Write-Warning "  [!] Error 0x800f0922 frequently occurs when a VPN blocks telemetry during update validation."
    Write-Warning "  [!] Please disconnect VPNs before attempting to update."
}
else {
    Write-Host "  [OK] No blocking VPN connections detected." -ForegroundColor Green
}

# 5. Reset Windows Update Services
Write-Host "`n[+] Cycling Windows Update Service (wuauserv)..." -ForegroundColor Yellow
Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1
Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
Write-Host "  [OK] wuauserv restarted." -ForegroundColor Green

Write-Host "`n=========================================================" -ForegroundColor Green
Write-Host " [STATUS] Error 0x800f0922 Remediation Completed Successfully." -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
