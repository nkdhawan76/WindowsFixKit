$rootDir = Split-Path -Parent $PSScriptRoot
$scriptsDir = Join-Path $rootDir "scripts"

Describe "PowerShell Scripts Syntax & Structure Verification" {
    $allScripts = Get-ChildItem -Path $scriptsDir -Filter *.ps1 -Recurse

    foreach ($psScript in $allScripts) {
        $relName = $psScript.FullName.Replace($rootDir + "\", "")

        Context "Script: $relName" {
            It "Should parse completely with ZERO AST syntax errors" {
                $tokens = $null
                $errors = $null
                [System.Management.Automation.Language.Parser]::ParseFile($psScript.FullName, [ref]$tokens, [ref]$errors) | Out-Null
                $errors.Count | Should Be 0
            }

            It "Should include comment-based help block (.SYNOPSIS and .DESCRIPTION)" {
                $content = Get-Content -Path $psScript.FullName -Raw
                ($content -match "\.SYNOPSIS") | Should Be $true
                ($content -match "\.DESCRIPTION") | Should Be $true
            }

            It "Should contain [CmdletBinding()] or standard parameter block" {
                $content = Get-Content -Path $psScript.FullName -Raw
                $hasParam = ($content -match "\[CmdletBinding\(\)\]") -or ($content -match "param\s*\(")
                $hasParam | Should Be $true
            }
        }
    }
}

Describe "Batch Script Fallbacks Verification" {
    $allBatches = Get-ChildItem -Path $scriptsDir -Filter *.bat -Recurse

    foreach ($bat in $allBatches) {
        Context "Batch Script: $($bat.Name)" {
            It "Should not be empty" {
                $bat.Length | Should BeGreaterThan 100
            }

            It "Should contain header marker and elevation check" {
                $content = Get-Content -Path $bat.FullName -Raw
                ($content -match "WindowsFixKit") | Should Be $true
                ($content -match "net session") | Should Be $true
            }
        }
    }
}
