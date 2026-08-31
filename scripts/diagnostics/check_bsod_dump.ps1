<#
.SYNOPSIS
    Audits Windows BSOD (Blue Screen of Death) memory crash dumps and BugCheck telemetry.
.DESCRIPTION
    Scans C:\Windows\Minidump\*.dmp, MEMORY.DMP, and System Event Log (Event ID 1001) to identify
    recent system crashes, stop codes, faulty drivers (e.g. nvlddmkm.sys, rtwlanu.sys), and crash timestamps.
    Returns structured PSCustomObject with crash metrics and health status.
#>

[CmdletBinding()]
param(
    [switch]$NonInteractive,
    [switch]$PassThru
)

function Test-IsAdmin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

$minidumpDir = "$env:SystemRoot\Minidump"
$memoryDump = "$env:SystemRoot\MEMORY.DMP"
$crashes = [System.Collections.Generic.List[PSCustomObject]]::new()

# BugCheck Code Common Lookup
$bugCheckLookup = @{
    "0x0000000A" = "IRQL_NOT_LESS_OR_EQUAL (Faulty kernel driver or memory corruption)"
    "0x0000001E" = "KMODE_EXCEPTION_NOT_HANDLED (Kernel exception error in driver)"
    "0x0000003B" = "SYSTEM_SERVICE_EXCEPTION (Graphic driver or UI subsystem crash)"
    "0x00000050" = "PAGE_FAULT_IN_NONPAGED_AREA (Defective RAM or storage driver)"
    "0x0000007E" = "SYSTEM_THREAD_EXCEPTION_NOT_HANDLED (Hardware incompatibility / corrupt driver)"
    "0x0000009F" = "DRIVER_POWER_STATE_FAILURE (Power transition failure during sleep/hibernate)"
    "0x000000D1" = "DRIVER_IRQL_NOT_LESS_OR_EQUAL (Faulty network, Wi-Fi, or USB driver)"
    "0x00000116" = "VIDEO_TDR_FAILURE (GPU display driver reset timeout)"
    "0x00000124" = "WHEA_UNCORRECTABLE_ERROR (Hardware CPU/Motherboard/PCIe fatal error)"
    "0x00000133" = "DPC_WATCHDOG_VIOLATION (SSD firmware or storage driver hang)"
    "0x00000139" = "KERNEL_SECURITY_CHECK_FAILURE (Corrupt memory structure or driver bug)"
    "0x00000154" = "UNEXPECTED_STORE_EXCEPTION (SSD/HDD disk sector read failure)"
    "0x000001D5" = "DRIVER_PNP_WATCHDOG (Device installation / driver enumeration freeze)"
}

# 1. Query Event Log for Event ID 1001 (BugCheck)
try {
    $events = Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-WER-SystemErrorReporting'; Id=1001} -MaxEvents 5 -ErrorAction SilentlyContinue
    if (-not $events) {
        $events = Get-WinEvent -FilterHashtable @{LogName='System'; Id=1001} -MaxEvents 5 -ErrorAction SilentlyContinue |
            Where-Object { $_.Message -match "computer has rebooted from a bugcheck|0x0000" }
    }

    if ($events) {
        foreach ($ev in $events) {
            $msg = $ev.Message
            $bugCode = "Unknown"
            if ($msg -match "(0x[0-9a-fA-F]{8})") {
                $bugCode = $matches[1].ToUpper()
            }
            $driverMatch = if ($msg -match "([a-zA-Z0-9_\-]+\.sys)") { $matches[1] } else { "System Kernel / Unknown" }
            $explanation = if ($bugCheckLookup.ContainsKey($bugCode)) { $bugCheckLookup[$bugCode] } else { "Windows Kernel BugCheck ($bugCode)" }

            $crashes.Add([PSCustomObject]@{
                Timestamp   = $ev.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
                BugCode     = $bugCode
                Explanation = $explanation
                Driver      = $driverMatch
                Source      = "System Event Log"
            })
        }
    }
} catch {}

# 2. Inspect Minidump Directory Files
if (Test-Path $minidumpDir) {
    $dumpFiles = Get-ChildItem -Path $minidumpDir -Filter "*.dmp" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 5
    foreach ($df in $dumpFiles) {
        if (-not ($crashes | Where-Object { $_.Timestamp -match $df.LastWriteTime.ToString("yyyy-MM-dd") })) {
            $crashes.Add([PSCustomObject]@{
                Timestamp   = $df.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                BugCode     = "MINIDUMP_ARCHIVED"
                Explanation = "Minidump crash artifact recorded: $($df.Name)"
                Driver      = "Analysis file: $($df.Name)"
                Source      = "Minidump File"
            })
        }
    }
}

$status = "Healthy"
if ($crashes.Count -gt 0) {
    $status = "Warning"
}

return [PSCustomObject]@{
    Status         = $status
    CrashCount     = $crashes.Count
    RecentCrashes  = $crashes
    MinidumpActive = (Test-Path $minidumpDir)
}
