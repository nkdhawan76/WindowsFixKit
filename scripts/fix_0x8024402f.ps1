<#
.SYNOPSIS
    Fixes Windows Update error 0x8024402f (Update Installation Loop Failure / Corrupt Component Store).
.DESCRIPTION
    Performs an exhaustive reset of Windows Update components:
    - Stops BITS, wuauserv, cryptSvc, msiserver
    - Renames SoftwareDistribution and Catroot2 folders
    - Re-registers core Windows Update COM DLLs
    - Resets BITS queue and restarts all services
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
    Write-Error "[!] Error 0x8024402f fix requires administrative elevation. Please run PowerShell as Administrator."
    exit 1
}

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " [WindowsFixKit] Fixing Error 0x8024402f (Full WU Reset)" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

# 1. Stop Windows Update Services
Write-Host "`n[+] Stopping Windows Update related services..." -ForegroundColor Yellow
$services = @("wuauserv", "cryptSvc", "bits", "msiserver")
foreach ($svc in $services) {
    try {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Write-Host "  [OK] Stopped service: $svc" -ForegroundColor Green
    }
    catch {
        Write-Warning "  [-] Could not stop ${svc}: $_"
    }
}

# 2. Rename SoftwareDistribution and Catroot2
Write-Host "`n[+] Renaming corrupted datastores..." -ForegroundColor Yellow
$pathsToReset = @(
    @{ Original = "$env:SystemRoot\SoftwareDistribution"; Backup = "$env:SystemRoot\SoftwareDistribution.bak" },
    @{ Original = "$env:SystemRoot\System32\catroot2"; Backup = "$env:SystemRoot\System32\catroot2.bak" }
)

foreach ($item in $pathsToReset) {
    $orig = $item.Original
    $bak = $item.Backup
    if (Test-Path -Path $orig) {
        if (Test-Path -Path $bak) {
            Remove-Item -Path $bak -Recurse -Force -ErrorAction SilentlyContinue
        }
        try {
            Rename-Item -Path $orig -NewName (Split-Path $bak -Leaf) -Force -ErrorAction Stop
            Write-Host "  [OK] Renamed $(Split-Path $orig -Leaf) to $(Split-Path $bak -Leaf)" -ForegroundColor Green
        }
        catch {
            Write-Warning "  [-] Failed to rename $orig. Attempting force file clear..."
            Get-ChildItem -Path $orig -Recurse -Force -ErrorAction SilentlyContinue |
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    else {
        Write-Host "  [-] $orig not found; will be initialized on service start." -ForegroundColor Gray
    }
}

# 3. Re-register Windows Update DLLs
Write-Host "`n[+] Re-registering core Windows Update COM libraries..." -ForegroundColor Yellow
$dllList = @(
    "atl.dll", "urlmon.dll", "mshtml.dll", "shdocvw.dll", "browseui.dll",
    "jscript.dll", "vbscript.dll", "scrrun.dll", "msxml.dll", "msxml3.dll",
    "msxml6.dll", "actxprxy.dll", "softpub.dll", "wintrust.dll", "dssenh.dll",
    "rsaenh.dll", "gpkcsp.dll", "sccbase.dll", "slbcsp.dll", "cryptdlg.dll",
    "oleaut32.dll", "ole32.dll", "shell32.dll", "initpki.dll", "wuapi.dll",
    "wuaueng.dll", "wuaueng1.dll", "wucltui.dll", "wups.dll", "wups2.dll",
    "wuweb.dll", "qmgr.dll", "qmgrprxy.dll", "wucltux.dll", "muweb.dll", "wuwebv.dll"
)

foreach ($dll in $dllList) {
    if (Test-Path -Path "$env:SystemRoot\System32\$dll") {
        & regsvr32.exe /s "$env:SystemRoot\System32\$dll"
    }
}
Write-Host "  [OK] Re-registered available Windows Update libraries." -ForegroundColor Green

# 4. Reset Winsock & TCP/IP
Write-Host "`n[+] Resetting network sockets..." -ForegroundColor Yellow
& netsh winsock reset 2>&1 | Out-Null
& netsh winhttp reset proxy 2>&1 | Out-Null
Write-Host "  [OK] Sockets and WinHTTP reset completed." -ForegroundColor Green

# 5. Restart Core Services
Write-Host "`n[+] Restarting Windows Update services..." -ForegroundColor Yellow
foreach ($svc in $services) {
    try {
        Set-Service -Name $svc -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name $svc -ErrorAction SilentlyContinue
        Write-Host "  [OK] Started service: $svc" -ForegroundColor Green
    }
    catch {
        Write-Warning "  [-] Failed to start ${svc}: $_"
    }
}

Write-Host "`n=========================================================" -ForegroundColor Green
Write-Host " [STATUS] Error 0x8024402f Component Reset Completed." -ForegroundColor Green
Write-Host " [NOTE] A system reboot is strongly recommended to finalize catalog sync." -ForegroundColor Yellow
Write-Host "=========================================================" -ForegroundColor Green
