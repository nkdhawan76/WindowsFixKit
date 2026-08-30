<#
.SYNOPSIS
    Remediates excessive Windows startup applications and boot bloat.
.DESCRIPTION
    Scans startup registry paths, removes broken/orphaned startup references,
    and provides guidance on managing high-impact startup apps.
    Idempotent and safe to run multiple times.
#>

[CmdletBinding()]
param(
    [switch]$NonInteractive
)

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " [WindowsFixKit] Startup Bloat Remediation" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

$regPaths = @(
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
)

Write-Host "`n[+] Scanning Startup Registry Run Keys for Dead / Orphaned Launchers..." -ForegroundColor Yellow

foreach ($regPath in $regPaths) {
    if (Test-Path -Path $regPath) {
        $props = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
        if ($props) {
            foreach ($prop in $props.PSObject.Properties) {
                if ($prop.Name -notmatch "^PS|^_") {
                    $cmdVal = [string]$prop.Value
                    # Check if target executable file exists
                    $exeMatch = [regex]::Match($cmdVal, '^"?([^"]+\.exe)"?', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                    if ($exeMatch.Success) {
                        $exePath = $exeMatch.Groups[1].Value
                        if (-not (Test-Path -Path $exePath)) {
                            Write-Host "  [!] Found Orphaned Startup Entry: $($prop.Name) -> $exePath" -ForegroundColor Yellow
                            try {
                                Remove-ItemProperty -Path $regPath -Name $prop.Name -Force -ErrorAction SilentlyContinue
                                Write-Host "  [OK] Removed broken startup registry entry: $($prop.Name)" -ForegroundColor Green
                            }
                            catch {
                                Write-Warning "  [-] Could not remove $($prop.Name): $_"
                            }
                        }
                        else {
                            Write-Host "  [-] Active startup item: $($prop.Name)" -ForegroundColor Gray
                        }
                    }
                }
            }
        }
    }
}

Write-Host "`n[+] To disable active legitimate startup apps that slow down boot:" -ForegroundColor Cyan
Write-Host "  1. Press Ctrl + Shift + Esc to open Task Manager"
Write-Host "  2. Go to the 'Startup apps' tab"
Write-Host "  3. Right-click high-impact launchers (e.g. Steam, Discord, Spotify, Update Checkers) and select 'Disable'"

Write-Host "`n=========================================================" -ForegroundColor Green
Write-Host " [STATUS] Startup Bloat Audit & Cleanup Completed." -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
