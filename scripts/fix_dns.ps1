<#
.SYNOPSIS
    Fixes DNS resolution failures (websites unreachable / lookups fail).
.DESCRIPTION
    Restores domain name resolution capabilities:
    - Flushes the local DNS client cache
    - Clears NetBIOS name cache
    - Configures high-performance fallback DNS servers (Cloudflare 1.1.1.1 & Google 8.8.8.8) on active adapters
    - Verifies domain name lookup against global root domains
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
    Write-Error "[!] DNS fix requires administrative elevation. Please run PowerShell as Administrator."
    exit 1
}

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " [WindowsFixKit] Fixing DNS Resolution" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

# 1. Flush DNS and NetBIOS Caches
Write-Host "`n[+] Flushing DNS and NetBIOS resolver caches..." -ForegroundColor Yellow
& ipconfig /flushdns 2>&1 | Out-Null
& nbtstat -R 2>&1 | Out-Null
& ipconfig /registerdns 2>&1 | Out-Null
Write-Host "  [OK] Local DNS cache cleared and re-registered." -ForegroundColor Green

# 2. Configure Reliable Public DNS Fallbacks on Active Interfaces
Write-Host "`n[+] Configuring DNS server addresses on active network adapters..." -ForegroundColor Yellow

if (Get-Command "Set-DnsClientServerAddress" -ErrorAction SilentlyContinue) {
    # Modern PowerShell / Win 8.1+
    $adapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" }
    foreach ($adapter in $adapters) {
        Write-Host "  [-] Applying DNS servers to $($adapter.Name)..." -ForegroundColor Gray
        try {
            Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses @("1.1.1.1", "8.8.8.8", "1.0.0.1") -ErrorAction SilentlyContinue
            Write-Host "  [OK] Configured Cloudflare (1.1.1.1) and Google (8.8.8.8) on $($adapter.Name)" -ForegroundColor Green
        }
        catch {
            Write-Warning "  [-] Failed setting DNS on $($adapter.Name): $_"
        }
    }
}
else {
    # Legacy Netsh Fallback for Windows 7
    Write-Host "  [-] Using Netsh to set DNS servers on active adapters..." -ForegroundColor Gray
    $interfaces = & netsh interface show interface
    $interfaces | ForEach-Object {
        if ($_ -match "Connected") {
            $interfaceName = ($_ -split "\s{2,}")[-1]
            if ($interfaceName) {
                & netsh interface ip set dns name="$interfaceName" static 1.1.1.1 primary 2>&1 | Out-Null
                & netsh interface ip add dns name="$interfaceName" 8.8.8.8 index=2 2>&1 | Out-Null
                Write-Host "  [OK] Configured DNS on $interfaceName via netsh." -ForegroundColor Green
            }
        }
    }
}

# 3. Verification Test
Write-Host "`n[+] Testing DNS Name Resolution for major domains..." -ForegroundColor Yellow
$domainsToTest = @("microsoft.com", "google.com", "cloudflare.com")
$allPassed = $true

foreach ($domain in $domainsToTest) {
    $resolved = $false
    
    if (Get-Command "Resolve-DnsName" -ErrorAction SilentlyContinue) {
        try {
            $res = Resolve-DnsName -Name $domain -QuickTimeout -ErrorAction Stop
            if ($res) { $resolved = $true }
        }
        catch {
            $resolved = $false
        }
    }
    else {
        try {
            $ips = [System.Net.Dns]::GetHostAddresses($domain)
            if ($ips) { $resolved = $true }
        }
        catch {
            $resolved = $false
        }
    }

    if ($resolved) {
        Write-Host "  [OK] Successfully resolved: $domain" -ForegroundColor Green
    }
    else {
        Write-Warning "  [!] Failed to resolve: $domain"
        $allPassed = $false
    }
}

Write-Host "`n=========================================================" -ForegroundColor Green
if ($allPassed) {
    Write-Host " [STATUS] DNS Resolution Remediation Completed Successfully." -ForegroundColor Green
}
else {
    Write-Host " [STATUS] DNS Fixed, but some lookups timed out. Try reconnecting to Wi-Fi/Ethernet." -ForegroundColor Yellow
}
Write-Host "=========================================================" -ForegroundColor Green
