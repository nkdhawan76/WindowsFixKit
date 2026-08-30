$rootDir = Split-Path -Parent $PSScriptRoot
$diagDir = Join-Path $rootDir "scripts\diagnostics"

Describe "Modular Diagnostics Subsystem Verification" {
    $diagScripts = Get-ChildItem -Path $diagDir -Filter *.ps1

    It "Should contain all required diagnostic modules" {
        $names = $diagScripts.Name
        ($names -contains "check_os_info.ps1") | Should Be $true
        ($names -contains "check_disk_health.ps1") | Should Be $true
        ($names -contains "check_ram_health.ps1") | Should Be $true
        ($names -contains "check_battery_health.ps1") | Should Be $true
        ($names -contains "check_cpu_temp.ps1") | Should Be $true
        ($names -contains "check_startup_apps.ps1") | Should Be $true
    }

    foreach ($diag in $diagScripts) {
        Context "Diagnostic Module: $($diag.Name)" {
            It "Should declare the -PassThru switch parameter" {
                $content = Get-Content -Path $diag.FullName -Raw
                ($content -match '\[switch\]\$PassThru') | Should Be $true
            }

            It "Should execute cleanly in PassThru mode and return an object with Status property" {
                $result = & $diag.FullName -PassThru
                $result | Should Not BeNullOrEmpty
                $result.Status | Should Not BeNullOrEmpty
                ($result.Status -match "^(Healthy|Warning|Critical)$") | Should Be $true
            }
        }
    }
}
