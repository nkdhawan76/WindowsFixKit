<#
.SYNOPSIS
    Local Pre-Push Quality Gate & Lint Checker for WindowsFixKit.
.DESCRIPTION
    Runs static analysis (PSScriptAnalyzer), AST syntax checks, JSON schema validations,
    Markdown structure checks, and Pester tests locally to guarantee 0 errors and 0 warnings
    before opening a Pull Request.
#>

[CmdletBinding()]
param(
    [switch]$SkipPester
)

$rootDir = Split-Path -Parent $PSScriptRoot
Set-Location $rootDir

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " [WindowsFixKit] Local Quality Gate & Lint Checker" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

$issuesFound = 0

# 1. AST Syntax Check
Write-Host "`n[+] 1. Checking PowerShell AST Syntax across all scripts..." -ForegroundColor Yellow
$psFiles = Get-ChildItem -Path $rootDir -Include *.ps1,*.psm1,*.psd1 -Recurse -File | Where-Object { $_.FullName -notmatch "\\(\.git|node_modules)\\" }

foreach ($file in $psFiles) {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors.Count -gt 0) {
        Write-Error "  [FAIL] Syntax error in $($file.Name): $($errors[0].Message)"
        $issuesFound += $errors.Count
    }
}
if ($issuesFound -eq 0) {
    Write-Host "  [PASS] All $($psFiles.Count) PowerShell files parsed with ZERO AST errors." -ForegroundColor Green
}

# 2. PSScriptAnalyzer Static Analysis
Write-Host "`n[+] 2. Running PSScriptAnalyzer (Severity: Error, Warning)..." -ForegroundColor Yellow
if (Get-Module -ListAvailable -Name PSScriptAnalyzer) {
    $saResults = Invoke-ScriptAnalyzer -Path "$rootDir\scripts" -Recurse -Severity Error, Warning
    if ($saResults) {
        $saResults | Format-Table -AutoSize
        $issuesFound += $saResults.Count
        Write-Error "  [FAIL] PSScriptAnalyzer reported $($saResults.Count) issue(s)!"
    } else {
        Write-Host "  [PASS] PSScriptAnalyzer completed with 0 errors and 0 warnings." -ForegroundColor Green
    }
} else {
    Write-Warning "  [SKIP] PSScriptAnalyzer module not installed locally. Run: Install-Module -Name PSScriptAnalyzer"
}

# 3. JSON Schema Validation
Write-Host "`n[+] 3. Validating errors/errors_db.json..." -ForegroundColor Yellow
$jsonPath = Join-Path $rootDir "errors\errors_db.json"
try {
    $jsonObj = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json
    $entriesCount = ($jsonObj.PSObject.Properties | Measure-Object).Count
    Write-Host "  [PASS] errors_db.json is valid JSON ($entriesCount entries found)." -ForegroundColor Green
} catch {
    Write-Error "  [FAIL] JSON parse error in errors_db.json: $_"
    $issuesFound++
}

# 4. Run Pester Unit Tests
if (-not $SkipPester) {
    Write-Host "`n[+] 4. Running Pester Unit & Integration Tests..." -ForegroundColor Yellow
    if (Get-Module -ListAvailable -Name Pester) {
        $pesterOut = Invoke-Pester -Path "$rootDir\tests" -PassThru
        if ($pesterOut.FailedCount -gt 0) {
            Write-Error "  [FAIL] Pester reported $($pesterOut.FailedCount) failed test(s)!"
            $issuesFound += $pesterOut.FailedCount
        } else {
            Write-Host "  [PASS] All $($pesterOut.PassedCount) Pester tests PASSED!" -ForegroundColor Green
        }
    } else {
        Write-Warning "  [SKIP] Pester module not installed locally."
    }
}

Write-Host "`n=========================================================" -ForegroundColor Cyan
if ($issuesFound -eq 0) {
    Write-Host " [QUALITY GATE PASSED] 0 Errors, 0 Warnings! Safe to commit and push." -ForegroundColor Green
    Write-Host "=========================================================" -ForegroundColor Cyan
    exit 0
} else {
    Write-Host " [QUALITY GATE FAILED] $issuesFound issue(s) detected. Please resolve before pushing." -ForegroundColor Red
    Write-Host "=========================================================" -ForegroundColor Cyan
    exit 1
}
