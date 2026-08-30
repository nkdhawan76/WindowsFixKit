<#
.SYNOPSIS
    Root Module for WindowsFixKit PowerShell Tooling.
.DESCRIPTION
    Exposes unified commands to invoke WindowsFixKit diagnostics, system audits, and remediations.
#>

function Invoke-WindowsFixKit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet("UpdateRepair", "Full", "ScanOnly", "StorageCleanup", "NetworkReset", "WiFiFix", "BluetoothFix")]
        [string]$DiagnosisType = "UpdateRepair",

        [switch]$NonInteractive
    )

    $moduleRoot = $PSScriptRoot
    $scriptsDir = Join-Path $moduleRoot "scripts"

    switch ($DiagnosisType) {
        "UpdateRepair" {
            & (Join-Path $scriptsDir "diagnose.ps1")
        }
        "Full" {
            & (Join-Path $scriptsDir "full_system_diagnosis.ps1")
        }
        "ScanOnly" {
            & (Join-Path $scriptsDir "diagnose.ps1") -ScanOnly
        }
        "StorageCleanup" {
            & (Join-Path $scriptsDir "fix_storage_cleanup.ps1")
        }
        "NetworkReset" {
            & (Join-Path $scriptsDir "fix_network_reset.ps1")
        }
        "WiFiFix" {
            & (Join-Path $scriptsDir "fix_wifi_missing.ps1")
        }
        "BluetoothFix" {
            & (Join-Path $scriptsDir "fix_bluetooth_missing.ps1")
        }
    }
}

Export-ModuleMember -Function Invoke-WindowsFixKit
