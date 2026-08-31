<#
.SYNOPSIS
    Safely tunes system performance by disabling non-critical background services and telemetry.
.DESCRIPTION
    Safely disables non-essential services (DiagTrack, dmwappushservice, Fax, and optionally
    Xbox services, Print Spooler, and OneDrive auto-start) based on explicit user confirmation.
    Preserves all core security, Windows Defender, and Windows Update services.
    Idempotent and safe to run multiple times.
#>

<#
================================================================================
CRITICAL SECURITY NOTICE FOR CONTRIBUTORS:
DO NOT EVER ADD WINDOWS DEFENDER, ANTISPYWARE, WINDOWS UPDATE (wuauserv), BITS,
OR ANY CORE SECURITY / CRYPTOGRAPHIC SERVICE DISABLING ROUTINES TO THIS SCRIPT.
Disabling Windows Defender or core security services leaves systems vulnerable
to malware and breaks organizational compliance. Such contributions will be
immediately rejected.
================================================================================
#>

[CmdletBinding()]
param(
    [switch]$NonInteractive,
    [switch]$DisableOneDrive,
    [switch]$DisableXbox,
    [switch]$DisablePrintSpooler
)

function Test-IsAdmin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Error "[!] Performance debloat requires administrative privileges. Please run as Administrator."
    exit 1
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "       WindowsFixKit - Safe Performance Debloat Engine           " -ForegroundColor Cyan
Write-Host "      DevSparks India | https://devsparksindia.com | 9521032268   " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

Write-Host "`n[!] Safety Assurance: Windows Defender, Windows Update, BITS, and Firewall remain fully active.`n" -ForegroundColor Green

if (-not $NonInteractive) {
    Write-Host "This utility will safely optimize background telemetry and idle services." -ForegroundColor Yellow
    $confirm = Read-Host "Do you want to proceed with safe service optimization? (Y/N)"
    if ($confirm -notmatch "^[yY]") {
        Write-Host "[!] Operation cancelled by user." -ForegroundColor Gray
        exit 0
    }
}

# Helper to safely configure service startup
function Set-SafeServiceState {
    param(
        [string]$ServiceName,
        [string]$DisplayName,
        [string]$TargetStartup = "Disabled"
    )

    $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($null -ne $svc) {
        try {
            if ($svc.Status -eq "Running") {
                Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
                Write-Host "  [-] Stopped service: $DisplayName ($ServiceName)" -ForegroundColor Gray
            }
            Set-Service -Name $ServiceName -StartupType $TargetStartup -ErrorAction Stop
            Write-Host "  [OK] $DisplayName ($ServiceName) set to $TargetStartup." -ForegroundColor Green
        } catch {
            Write-Warning "  [-] Could not modify service $ServiceName : $_"
        }
    } else {
        Write-Host "  [-] Service $ServiceName not present on this system." -ForegroundColor Gray
    }
}

# 1. Telemetry & Diagnostic Services
Write-Host "`n[1/5] Optimizing Diagnostic Tracking & Push Services..." -ForegroundColor Yellow
Set-SafeServiceState -ServiceName "DiagTrack" -DisplayName "Connected User Experiences & Telemetry"
Set-SafeServiceState -ServiceName "dmwappushservice" -DisplayName "Device Management WAP Push Message Routing Service"

# 2. Legacy / Unused Services
Write-Host "`n[2/5] Optimizing Legacy Services..." -ForegroundColor Yellow
Set-SafeServiceState -ServiceName "Fax" -DisplayName "Windows Fax Service"

# 3. Xbox & Gaming Services (User Opt-in or flag)
Write-Host "`n[3/5] Checking Xbox & Gaming Background Services..." -ForegroundColor Yellow
$disableXboxOpt = $DisableXbox
if (-not $NonInteractive -and -not $DisableXbox) {
    $xboxPrompt = Read-Host "Do you use Xbox gaming features or Xbox App on this PC? (Y = Keep Xbox / N = Disable Xbox services)"
    if ($xboxPrompt -match "^[nN]") {
        $disableXboxOpt = $true
    }
}

if ($disableXboxOpt) {
    Write-Host "  [-] Disabling Xbox background authentication and live services..." -ForegroundColor Yellow
    Set-SafeServiceState -ServiceName "XblAuthManager" -DisplayName "Xbox Live Auth Manager"
    Set-SafeServiceState -ServiceName "XblGameSave" -DisplayName "Xbox Live Game Save"
    Set-SafeServiceState -ServiceName "XboxNetApiSvc" -DisplayName "Xbox Live Networking Service"
} else {
    Write-Host "  [+] Xbox gaming services preserved as requested." -ForegroundColor Green
}

# 4. Print Spooler Service (Only if user has no physical/virtual printer)
Write-Host "`n[4/5] Checking Print Spooler Service..." -ForegroundColor Yellow
$disableSpoolerOpt = $DisablePrintSpooler
if (-not $NonInteractive -and -not $DisablePrintSpooler) {
    $spoolerPrompt = Read-Host "Do you use physical or PDF printers on this PC? (Y = Keep Spooler / N = Disable Spooler)"
    if ($spoolerPrompt -match "^[nN]") {
        $disableSpoolerOpt = $true
    }
}

if ($disableSpoolerOpt) {
    Set-SafeServiceState -ServiceName "Spooler" -DisplayName "Print Spooler"
} else {
    Write-Host "  [+] Print Spooler preserved for printing tasks." -ForegroundColor Green
}

# 5. OneDrive Autostart (Only if user opts in)
Write-Host "`n[5/5] Checking OneDrive Startup Configuration..." -ForegroundColor Yellow
$disableOD = $DisableOneDrive
if (-not $NonInteractive -and -not $DisableOneDrive) {
    $odPrompt = Read-Host "Do you want to disable OneDrive starting automatically on boot? (Y/N)"
    if ($odPrompt -match "^[yY]") {
        $disableOD = $true
    }
}

if ($disableOD) {
    $runPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    if (Get-ItemProperty -Path $runPath -Name "OneDrive" -ErrorAction SilentlyContinue) {
        Remove-ItemProperty -Path $runPath -Name "OneDrive" -Force -ErrorAction SilentlyContinue
        Write-Host "  [OK] OneDrive autostart disabled from registry." -ForegroundColor Green
    } else {
        Write-Host "  [-] OneDrive autostart entry was not active in user registry." -ForegroundColor Gray
    }
} else {
    Write-Host "  [+] OneDrive autostart setting unchanged." -ForegroundColor Green
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host " [STATUS] Safe Performance Debloat Completed Successfully." -ForegroundColor Green
Write-Host "=================================================================`n" -ForegroundColor Cyan
