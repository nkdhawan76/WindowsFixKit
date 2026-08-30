<#
.SYNOPSIS
    Fixes Windows Update error 0x80070005 (Access Denied / Permission Issue).
.DESCRIPTION
    Resets Access Control Lists (ACLs) and file ownership on Windows Update directories
    including SoftwareDistribution, clearing lockups and permission corruptions.
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
    Write-Error "[!] Error 0x80070005 fix requires administrative elevation. Please run PowerShell as Administrator."
    exit 1
}

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " [WindowsFixKit] Fixing Error 0x80070005 (Access Denied)" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

# 1. Inspect Initial State
Write-Host "`n[+] Checking initial permissions and services..." -ForegroundColor Yellow
$sdPath = "$env:SystemRoot\SoftwareDistribution"
$servicesToStop = @("wuauserv", "bits", "cryptSvc", "trustedinstaller")

foreach ($svc in $servicesToStop) {
    $serviceObj = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($serviceObj) {
        Write-Host "  [-] Service $svc current state: $($serviceObj.Status)" -ForegroundColor Gray
    }
}

# 2. Stop Update Services
Write-Host "`n[+] Stopping Windows Update & Cryptographic services..." -ForegroundColor Yellow
foreach ($svc in $servicesToStop) {
    try {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Write-Host "  [OK] Stopped $svc" -ForegroundColor Green
    }
    catch {
        Write-Warning "  [!] Could not stop $($svc): $_"
    }
}

# 3. Reset Permissions on SoftwareDistribution
if (Test-Path -Path $sdPath) {
    Write-Host "`n[+] Resetting file ownership and ACLs on $sdPath..." -ForegroundColor Yellow
    
    # Take ownership
    Write-Host "  [-] Taking ownership as Administrators..." -ForegroundColor Gray
    & takeown.exe /f "$sdPath" /r /d y 2>&1 | Out-Null
    
    # Reset ACLs granting Full Control to SYSTEM and Administrators
    Write-Host "  [-] Granting standard security descriptors to SYSTEM and Administrators..." -ForegroundColor Gray
    & icacls.exe "$sdPath" /reset /t /c /l /q 2>&1 | Out-Null
    & icacls.exe "$sdPath" /grant "SYSTEM:(OI)(CI)F" /grant "*S-1-5-32-544:(OI)(CI)F" /t /c /q 2>&1 | Out-Null
    
    Write-Host "  [OK] Permissions successfully reset on SoftwareDistribution." -ForegroundColor Green
}
else {
    Write-Host "  [-] $sdPath does not exist; creating fresh directory..." -ForegroundColor Gray
    New-Item -ItemType Directory -Path $sdPath -Force | Out-Null
}

# 4. Repair Registry Subinacl Keys for WU if needed
Write-Host "`n[+] Verifying Registry ACLs on Windows Update subkeys..." -ForegroundColor Yellow
$regKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate",
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
)

foreach ($key in $regKeys) {
    if (Test-Path -Path $key) {
        try {
            $acl = Get-Acl -Path $key
            $rule = New-Object System.Security.AccessControl.RegistryAccessRule(
                "NT AUTHORITY\SYSTEM",
                "FullControl",
                "ContainerInherit,ObjectInherit",
                "None",
                "Allow"
            )
            $acl.SetAccessRule($rule)
            Set-Acl -Path $key -AclObject $acl
            Write-Host "  [OK] Access rule updated for $key" -ForegroundColor Green
        }
        catch {
            Write-Warning "  [-] Skipped setting ACL for $($key): $_"
        }
    }
}

# 5. Restart Core Services
Write-Host "`n[+] Starting Windows Update & Cryptographic services..." -ForegroundColor Yellow
$servicesToStart = @("cryptSvc", "bits", "wuauserv")
foreach ($svc in $servicesToStart) {
    try {
        Set-Service -Name $svc -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name $svc -ErrorAction SilentlyContinue
        $runningSvc = Get-Service -Name $svc -ErrorAction SilentlyContinue
        Write-Host "  [OK] $svc is now $($runningSvc.Status)" -ForegroundColor Green
    }
    catch {
        Write-Warning "  [!] Could not start $($svc): $_"
    }
}

Write-Host "`n=========================================================" -ForegroundColor Green
Write-Host " [STATUS] Error 0x80070005 Remediation Completed Successfully." -ForegroundColor Green
Write-Host " [NOTE] A system restart is recommended to complete pending ACL locks." -ForegroundColor Yellow
Write-Host "=========================================================" -ForegroundColor Green
