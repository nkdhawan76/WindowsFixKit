$rootDir = Split-Path -Parent $PSScriptRoot
$errorsDbPath = Join-Path $rootDir "errors\errors_db.json"

Describe "Errors Database Validation (errors_db.json)" {
    Context "File Integrity & JSON Schema" {
        It "Should exist at errors/errors_db.json" {
            Test-Path -Path $errorsDbPath | Should Be $true
        }

        It "Should parse as valid JSON without errors" {
            $jsonContent = Get-Content -Path $errorsDbPath -Raw | ConvertFrom-Json
            $jsonContent | Should Not BeNullOrEmpty
        }

        It "Should contain known error codes and hardware failure categories" {
            $jsonContent = Get-Content -Path $errorsDbPath -Raw | ConvertFrom-Json
            $props = $jsonContent.PSObject.Properties.Name
            $props.Count | Should BeGreaterThan 5
            $props -contains "0x80070005" | Should Be $true
            $props -contains "0x8024402c" | Should Be $true
            $props -contains "0x8024402f" | Should Be $true
            $props -contains "wifi_missing_post_update" | Should Be $true
            $props -contains "bluetooth_missing_post_update" | Should Be $true
            $props -contains "network_no_internet" | Should Be $true
            $props -contains "dns_not_resolving" | Should Be $true
        }
    }

    Context "Entry Completeness & Disk Reference Resolution" {
        $json = Get-Content -Path $errorsDbPath -Raw | ConvertFrom-Json
        $entries = $json.PSObject.Properties

        foreach ($entry in $entries) {
            $key = $entry.Name
            $data = $entry.Value

            It "[$key] Should have non-empty title, description, and category" {
                $data.title | Should Not BeNullOrEmpty
                $data.description | Should Not BeNullOrEmpty
                $data.category | Should Not BeNullOrEmpty
            }

            It "[$key] Should contain a non-empty manual_steps array" {
                $data.manual_steps | Should Not BeNullOrEmpty
                $data.manual_steps.Count | Should BeGreaterThan 0
            }

            It "[$key] Referenced fix_script '$($data.fix_script)' MUST exist on disk" {
                if ($data.fix_script) {
                    $fixPath = Join-Path $rootDir $data.fix_script
                    Test-Path -Path $fixPath | Should Be $true
                }
            }

            It "[$key] Referenced fallback_script '$($data.fallback_script)' MUST exist on disk if specified" {
                if ($data.fallback_script) {
                    $fallbackPath = Join-Path $rootDir $data.fallback_script
                    Test-Path -Path $fallbackPath | Should Be $true
                }
            }
        }
    }
}
