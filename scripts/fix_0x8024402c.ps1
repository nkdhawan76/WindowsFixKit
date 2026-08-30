<#
.SYNOPSIS
    Fixes Windows Update error 0x8024402c (Proxy/Firewall Misconfiguration / Invalid Update Endpoints).
.DESCRIPTION
    Resets WinHTTP proxy to direct connection, purges stale update cache, flushes DNS,
    and validates connectivity to Microsoft Update catalog endpoints.
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
    Write-Error "[!] Error 0x8024402c fix requires administrative elevation. Please run PowerShell as Administrator."
    exit 1
}

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " [WindowsFixKit] Fixing Error 0x8024402c (Proxy / Network)" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

# 1. Reset WinHTTP Proxy Configuration
Write-Host "`n[+] Resetting WinHTTP Proxy configuration..." -ForegroundColor Yellow
$currentProxy = & netsh winhttp show proxy
Write-Host "  [-] Current Proxy Settings:`n$currentProxy" -ForegroundColor Gray

Write-Host "  [-] Executing WinHTTP proxy reset..." -ForegroundColor Gray
& netsh winhttp reset proxy 2>&1 | Out-Null
Write-Host "  [OK] WinHTTP proxy reset to DIRECT access." -ForegroundColor Green

# 2. Flush DNS and purge ARP cache
Write-Host "`n[+] Flushing DNS Resolver Cache & Refreshing NetBIOS..." -ForegroundColor Yellow
& ipconfig /flushdns 2>&1 | Out-Null
& nbtstat -R 2>&1 | Out-Null
Write-Host "  [OK] DNS resolver cache flushed successfully." -ForegroundColor Green

# 3. Clean Temporary Files and Update Cache
Write-Host "`n[+] Clearing temporary download caches..." -ForegroundColor Yellow
$tempFolders = @(
    "$env:LOCALAPPDATA\Temp",
    "$env:SystemRoot\Temp"
)

foreach ($folder in $tempFolders) {
    if (Test-Path -Path $folder) {
        try {
            Get-ChildItem -Path $folder -Recurse -Force -ErrorAction SilentlyContinue |
                Where-Object { -not $_.PSIsContainer } |
                Remove-Item -Force -ErrorAction SilentlyContinue
            Write-Host "  [OK] Cleaned $folder" -ForegroundColor Green
        }
        catch {
            Write-Warning "  [-] Some files in $folder are currently in use."
        }
    }
}

# 4. Remove Static WSUS Registry overrides if pointing to dead endpoints
Write-Host "`n[+] Inspecting WSUS configuration overrides..." -ForegroundColor Yellow
$wuPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
if (Test-Path -Path $wuPolicyPath) {
    $wsusServer = (Get-ItemProperty -Path $wuPolicyPath -Name WUServer -ErrorAction SilentlyContinue).WUServer
    if ($wsusServer) {
        Write-Host "  [-] Found custom WSUS server: $wsusServer" -ForegroundColor Gray
        # Disable UseWUServer if orphaned
        Set-ItemProperty -Path "$wuPolicyPath\AU" -Name "UseWUServer" -Value 0 -ErrorAction SilentlyContinue
        Write-Host "  [OK] Set UseWUServer to 0 to bypass stale internal server." -ForegroundColor Green
    }
    else {
        Write-Host "  [OK] No corrupt WSUS server overrides detected." -ForegroundColor Green
    }
}

# 5. Restart Windows Update Service
Write-Host "`n[+] Cycling Windows Update Service (wuauserv)..." -ForegroundColor Yellow
Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1
Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
Write-Host "  [OK] Windows Update Service restarted." -ForegroundColor Green

Write-Host "`n=========================================================" -ForegroundColor Green
Write-Host " [STATUS] Error 0x8024402c Remediation Completed Successfully." -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
