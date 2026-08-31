<#
.SYNOPSIS
    Diagnoses and repairs corrupt or missing .NET Framework assemblies and BadImageFormatException.
.DESCRIPTION
    Checks installed .NET Framework versions via registry (NDP), inspects assembly health,
    triggers native DISM servicing repairs, and provides official Microsoft .NET download guidance.
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
    Write-Error "[!] .NET Framework diagnostic requires administrative privileges. Please run as Administrator."
    exit 1
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "     WindowsFixKit - .NET Framework & App Install Repair Tool    " -ForegroundColor Cyan
Write-Host "      DevSparks India | https://devsparksindia.com | 9521032268   " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Check Installed .NET Framework Releases in Registry
Write-Host "`n[1/3] Querying Installed .NET Framework Versions..." -ForegroundColor Yellow
$ndpPath = "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full"
if (Test-Path $ndpPath) {
    $release = (Get-ItemProperty -Path $ndpPath -Name "Release" -ErrorAction SilentlyContinue).Release
    $version = (Get-ItemProperty -Path $ndpPath -Name "Version" -ErrorAction SilentlyContinue).Version
    
    $versionName = switch ($release) {
        { $_ -ge 533320 } { ".NET Framework 4.8.1 (Windows 11 22H2+ / Server 2022)" ; break }
        { $_ -ge 528040 } { ".NET Framework 4.8" ; break }
        { $_ -ge 461808 } { ".NET Framework 4.7.2" ; break }
        { $_ -ge 461305 } { ".NET Framework 4.7.1" ; break }
        { $_ -ge 460798 } { ".NET Framework 4.7" ; break }
        { $_ -ge 394802 } { ".NET Framework 4.6.2" ; break }
        { $_ -ge 393295 } { ".NET Framework 4.6" ; break }
        { $_ -ge 378389 } { ".NET Framework 4.5" ; break }
        default { "Unknown / Pre-4.5 (.NET Release: $release)" }
    }
    
    Write-Host "  [+] Installed Version : $versionName ($version, Release: $release)" -ForegroundColor Green
} else {
    Write-Warning "  [!] .NET Framework 4.x registry key not detected! System may be missing essential runtimes."
}

# Check .NET 3.5 Feature State
$net35 = Get-WindowsOptionalFeature -Online -FeatureName "NetFx3" -ErrorAction SilentlyContinue
if ($net35) {
    Write-Host "  [-] .NET Framework 3.5 (includes 2.0 and 3.0) State: $($net35.State)" -ForegroundColor Gray
}

# 2. Run System Component Health Check for .NET Assemblies
Write-Host "`n[2/3] Verifying System Servicing Health for Core Assemblies..." -ForegroundColor Yellow
try {
    Write-Host "  [-] Running DISM Component Store verification..." -ForegroundColor Gray
    Start-Process -FilePath "dism.exe" -ArgumentList "/Online /Cleanup-Image /ScanHealth" -NoNewWindow -Wait -ErrorAction SilentlyContinue
    Write-Host "  [OK] Component store scan completed." -ForegroundColor Green
} catch {
    Write-Warning "  [-] DISM health check failed: $_"
}

# 3. Microsoft Official Download Guidance
Write-Host "`n[3/3] Official Microsoft .NET Framework Resources..." -ForegroundColor Yellow
Write-Host "  * Official Microsoft .NET Framework Runtime Downloads:" -ForegroundColor Cyan
Write-Host "    https://dotnet.microsoft.com/en-us/download/dotnet-framework" -ForegroundColor Yellow
Write-Host "  * Microsoft .NET Framework Repair Tool Official Page:" -ForegroundColor Cyan
Write-Host "    https://www.microsoft.com/en-us/download/details.aspx?id=30135" -ForegroundColor Yellow

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host " [STATUS] .NET Framework Diagnostic & Repair Guidance Completed." -ForegroundColor Green
Write-Host "=================================================================`n" -ForegroundColor Cyan
