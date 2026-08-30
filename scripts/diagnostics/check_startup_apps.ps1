<#
.SYNOPSIS
    Analyzes Windows Startup Programs, Autostart Registries, and Boot Bloat.
.DESCRIPTION
    Enumerates startup applications via Win32_StartupCommand and Windows Run keys,
    identifies startup impact, and flags excessive startup loads (> 15 items).
#>

[CmdletBinding()]
param(
    [switch]$PassThru
)

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " [WindowsFixKit Diagnostic] Startup Programs & Bloat" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

$startupApps = [System.Collections.Generic.List[PSCustomObject]]::new()
$overallStatus = "Healthy"
$recommendations = [System.Collections.Generic.List[string]]::new()

Write-Host "`n[+] Enumerating Registered Startup Applications..." -ForegroundColor Yellow

# 1. Win32_StartupCommand
try {
    $wmiStartup = Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue
    if ($null -eq $wmiStartup) { $wmiStartup = Get-WmiObject Win32_StartupCommand -ErrorAction SilentlyContinue }
    if ($wmiStartup) {
        foreach ($app in $wmiStartup) {
            $startupApps.Add([PSCustomObject]@{
                Name     = $app.Name
                Command  = $app.Command
                Location = $app.Location
                User     = $app.User
            })
        }
    }
}
catch {
    Write-Warning "[-] Error querying Win32_StartupCommand: $_"
}

# 2. Registry Run Keys (HKCU / HKLM)
$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
)

foreach ($regPath in $regPaths) {
    if (Test-Path -Path $regPath) {
        try {
            $regProps = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
            if ($regProps) {
                foreach ($prop in $regProps.PSObject.Properties) {
                    if ($prop.Name -notmatch "^PS|^_") {
                        # Avoid duplicates
                        $exists = $startupApps | Where-Object { $_.Name -eq $prop.Name }
                        if (-not $exists) {
                            $startupApps.Add([PSCustomObject]@{
                                Name     = $prop.Name
                                Command  = $prop.Value
                                Location = $regPath
                                User     = if ($regPath -match "HKCU") { "CurrentUser" } else { "AllUsers" }
                            })
                        }
                    }
                }
            }
        }
        catch {
            Write-Verbose "[-] Skipped reading $regPath"
        }
    }
}

$appCount = $startupApps.Count
$isBloated = $appCount -gt 15

if ($isBloated) {
    $overallStatus = "Warning"
    $recommendations.Add("Found $appCount auto-start applications (>15 entries detected). This significantly slows down system boot times and consumes RAM. Run fix_startup_bloat.ps1 or disable unneeded background launchers in Task Manager -> Startup.")
}

Write-Host "  [-] Total Startup Applications Found: $appCount" -ForegroundColor $(if ($isBloated) { "Yellow" } else { "Green" })

$displayLimit = [math]::Min(10, $appCount)
for ($i = 0; $i -lt $displayLimit; $i++) {
    $app = $startupApps[$i]
    Write-Host "      [$($i+1)] $($app.Name) -> $($app.Command)" -ForegroundColor Gray
}
if ($appCount -gt 10) {
    Write-Host "      ... and $($appCount - 10) more startup entries." -ForegroundColor Gray
}

$result = [PSCustomObject]@{
    StartupApps     = $startupApps
    TotalCount      = $appCount
    IsBloated       = $isBloated
    Status          = $overallStatus
    Recommendations = $recommendations
}

if ($PassThru) {
    return $result
}
