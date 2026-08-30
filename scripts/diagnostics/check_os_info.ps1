<#
.SYNOPSIS
    Gathers Operating System and Hardware System Specifications.
.DESCRIPTION
    Extracts OS edition, version, build number, architecture, hardware manufacturer,
    model, and system uptime using Get-ComputerInfo with legacy CIM/WMI fallbacks.
#>

[CmdletBinding()]
param(
    [switch]$PassThru
)

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " [WindowsFixKit Diagnostic] Operating System & Hardware" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

$osName = "Windows"
$osVersion = "Unknown"
$osBuild = "Unknown"
$osArch = "Unknown"
$hwManufacturer = "Unknown"
$hwModel = "Unknown"
$systemUptime = "Unknown"

# 1. Primary: Get-ComputerInfo (Win 10/11, modern PowerShell)
if (Get-Command "Get-ComputerInfo" -ErrorAction SilentlyContinue) {
    try {
        $compInfo = Get-ComputerInfo -Property WindowsProductName, WindowsVersion, WindowsBuildLabEx, OsArchitecture, CsManufacturer, CsModel, OsLastBootUpTime -ErrorAction Stop
        $osName = if ($compInfo.WindowsProductName) { $compInfo.WindowsProductName } else { (Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue).Caption }
        $osVersion = $compInfo.WindowsVersion
        $osBuild = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name CurrentBuild -ErrorAction SilentlyContinue).CurrentBuild
        if (-not $osBuild) { $osBuild = $compInfo.WindowsBuildLabEx }
        $osArch = $compInfo.OsArchitecture
        $hwManufacturer = $compInfo.CsManufacturer
        $hwModel = $compInfo.CsModel
        
        if ($compInfo.OsLastBootUpTime) {
            $uptimeSpan = (Get-Date) - $compInfo.OsLastBootUpTime
            $systemUptime = "{0}d {1}h {2}m" -f $uptimeSpan.Days, $uptimeSpan.Hours, $uptimeSpan.Minutes
        }
    }
    catch {
        Write-Warning "[-] Get-ComputerInfo query encountered error; switching to CIM fallback: $_"
    }
}

# 2. Fallback: CIM / WMI Objects (PowerShell 5.1 / Windows 7 / 8.1 compatibility)
if ($osName -eq "Windows" -or $hwManufacturer -eq "Unknown") {
    try {
        $osObj = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
        if ($null -eq $osObj) {
            $osObj = Get-WmiObject -Class Win32_OperatingSystem -ErrorAction SilentlyContinue
        }
        if ($osObj) {
            $osName = $osObj.Caption
            $osVersion = $osObj.Version
            $osBuild = $osObj.BuildNumber
            $osArch = $osObj.OSArchitecture
            if ($osObj.LastBootUpTime) {
                $bootTime = [Management.ManagementDateTimeConverter]::ToDateTime($osObj.LastBootUpTime)
                $uptimeSpan = (Get-Date) - $bootTime
                $systemUptime = "{0}d {1}h {2}m" -f $uptimeSpan.Days, $uptimeSpan.Hours, $uptimeSpan.Minutes
            }
        }

        $csObj = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
        if ($null -eq $csObj) {
            $csObj = Get-WmiObject -Class Win32_ComputerSystem -ErrorAction SilentlyContinue
        }
        if ($csObj) {
            $hwManufacturer = $csObj.Manufacturer
            $hwModel = $csObj.Model
        }
    }
    catch {
        Write-Warning "[-] Error during fallback system query: $_"
    }
}

Write-Host "  [-] Operating System   : $osName" -ForegroundColor Green
Write-Host "  [-] Build & Version    : $osVersion (Build $osBuild)" -ForegroundColor Green
Write-Host "  [-] Architecture       : $osArch" -ForegroundColor Green
Write-Host "  [-] Manufacturer       : $hwManufacturer" -ForegroundColor Green
Write-Host "  [-] Model              : $hwModel" -ForegroundColor Green
Write-Host "  [-] System Uptime      : $systemUptime" -ForegroundColor Green

$result = [PSCustomObject]@{
    OSName         = $osName
    OSVersion      = $osVersion
    OSBuild        = $osBuild
    OSArchitecture = $osArch
    Manufacturer   = $hwManufacturer
    Model          = $hwModel
    Uptime         = $systemUptime
    Status         = "Healthy"
}

if ($PassThru) {
    return $result
}
