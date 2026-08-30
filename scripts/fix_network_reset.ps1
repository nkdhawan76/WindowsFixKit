<#
.SYNOPSIS
    Fixes network connectivity issues (adapter connected with No Internet).
.DESCRIPTION
    Performs a complete network stack restoration:
    - Resets Winsock catalog
    - Resets IPv4 and IPv6 TCP/IP stacks
    - Flushes ARP tables and DNS cache
    - Releases and renews DHCP IP configurations
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
    Write-Error "[!] Network reset requires administrative elevation. Please run PowerShell as Administrator."
    exit 1
}

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " [WindowsFixKit] Full Network Stack Reset" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

# 1. Reset Winsock Catalog
Write-Host "`n[+] Resetting Winsock Catalog..." -ForegroundColor Yellow
$winsockOut = & netsh winsock reset 2>&1
Write-Host "  [-] $winsockOut" -ForegroundColor Gray
Write-Host "  [OK] Winsock catalog reset successfully." -ForegroundColor Green

# 2. Reset TCP/IP and IPv6 Stacks
Write-Host "`n[+] Resetting TCP/IP and IPv6 stack parameters..." -ForegroundColor Yellow
$resetLog = "$env:TEMP\netsh_ip_reset.log"
& netsh int ip reset "$resetLog" 2>&1 | Out-Null
& netsh int ipv6 reset 2>&1 | Out-Null
Write-Host "  [OK] TCP/IP and IPv6 stacks reset." -ForegroundColor Green

# 3. Purge ARP Cache and Routing Tables
Write-Host "`n[+] Clearing ARP cache and routing tables..." -ForegroundColor Yellow
& netsh interface ip delete arpcache 2>&1 | Out-Null
Write-Host "  [OK] ARP cache purged." -ForegroundColor Green

# 4. Release & Renew DHCP Leases
Write-Host "`n[+] Releasing and renewing DHCP configuration..." -ForegroundColor Yellow
& ipconfig /release 2>&1 | Out-Null
& ipconfig /renew 2>&1 | Out-Null
Write-Host "  [OK] DHCP leases refreshed." -ForegroundColor Green

# 5. Flush and Register DNS
Write-Host "`n[+] Flushing and re-registering DNS..." -ForegroundColor Yellow
& ipconfig /flushdns 2>&1 | Out-Null
& ipconfig /registerdns 2>&1 | Out-Null
Write-Host "  [OK] DNS cache flushed and re-registered." -ForegroundColor Green

Write-Host "`n=========================================================" -ForegroundColor Green
Write-Host " [STATUS] Network Stack Reset Completed Successfully." -ForegroundColor Green
Write-Host " [NOTE] A system reboot is required for socket changes to take full effect." -ForegroundColor Yellow
Write-Host "=========================================================" -ForegroundColor Green
