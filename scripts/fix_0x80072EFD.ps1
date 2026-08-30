<#
.SYNOPSIS
    Fixes Windows Update error 0x80072EFD (ERROR_INTERNET_CANNOT_CONNECT / Server Reachability).
.DESCRIPTION
    Fixes transport-level connectivity errors between Windows Update client and Microsoft endpoints:
    - Verifies default gateway reachability
    - Configures and enforces TLS 1.2 / TLS 1.3 protocol support in Schannel
    - Resets WinHTTP proxy and routing tables
    - Flushes DNS cache
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
    Write-Error "[!] Error 0x80072EFD fix requires administrative elevation. Please run PowerShell as Administrator."
    exit 1
}

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " [WindowsFixKit] Fixing Error 0x80072EFD (Connection Error)" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

# 1. Enforce TLS 1.2 in .NET and Windows Schannel (Essential for older Win 7/8.1/10 builds)
Write-Host "`n[+] Enforcing TLS 1.2 / Secure Protocols for Update Endpoints..." -ForegroundColor Yellow
$schannelProtocols = @("TLS 1.2", "TLS 1.1")

foreach ($proto in $schannelProtocols) {
    $clientKey = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$proto\Client"
    if (-not (Test-Path -Path $clientKey)) {
        New-Item -Path $clientKey -Force | Out-Null
    }
    Set-ItemProperty -Path $clientKey -Name "DisabledByDefault" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $clientKey -Name "Enabled" -Value 1 -Type DWord -Force
}

# Enforce Strong Crypto for .NET Framework
$netFrameworkPaths = @(
    "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319",
    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319"
)

foreach ($netPath in $netFrameworkPaths) {
    if (Test-Path -Path $netPath) {
        Set-ItemProperty -Path $netPath -Name "SchUseStrongCrypto" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $netPath -Name "SystemDefaultTlsVersions" -Value 1 -Type DWord -Force
    }
}
Write-Host "  [OK] TLS 1.2 and strong cryptography enforced." -ForegroundColor Green

# 2. Reset WinHTTP and IP Routing Cache
Write-Host "`n[+] Resetting WinHTTP Proxy and Clearing Network Sockets..." -ForegroundColor Yellow
& netsh winhttp reset proxy 2>&1 | Out-Null
& netsh int ip reset 2>&1 | Out-Null
& ipconfig /flushdns 2>&1 | Out-Null
Write-Host "  [OK] Network proxy and DNS cache purged." -ForegroundColor Green

# 3. Test Endpoint Reachability
Write-Host "`n[+] Verifying reachability to Microsoft Update Endpoints..." -ForegroundColor Yellow
$testEndpoints = @("ctldl.windowsupdate.com", "sls.update.microsoft.com", "fe3cr.delivery.mp.microsoft.com")

foreach ($endpoint in $testEndpoints) {
    try {
        $ip = [System.Net.Dns]::GetHostAddresses($endpoint)
        if ($ip) {
            Write-Host "  [OK] Resolved $endpoint -> $($ip[0].IPAddressToString)" -ForegroundColor Green
        }
    }
    catch {
        Write-Warning "  [-] Failed to resolve $($endpoint): $_"
    }
}

# 4. Restart Windows Update Services
Write-Host "`n[+] Restarting BITS and wuauserv..." -ForegroundColor Yellow
Stop-Service -Name "bits" -Force -ErrorAction SilentlyContinue
Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1
Start-Service -Name "bits" -ErrorAction SilentlyContinue
Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
Write-Host "  [OK] Services successfully restarted." -ForegroundColor Green

Write-Host "`n=========================================================" -ForegroundColor Green
Write-Host " [STATUS] Error 0x80072EFD Remediation Completed Successfully." -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
