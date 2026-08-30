# Contributing to WindowsFixKit

Thank you for contributing to **WindowsFixKit**! Our mission is to provide an open-source, reliable, and transparent diagnostic and auto-repair toolkit for Windows Update, networking, hardware health, and OS stability across Windows 7, 8.1, 10, and 11.

---

## 🛡️ Quality Gates & Branch Protection

To maintain high stability and prevent regressions:
- The **`main` branch is protected**: Direct pushes without PRs are restricted.
- **Mandatory CI Green Light**: Every Pull Request must pass the automated GitHub Actions CI suite (`ci.yml`):
  1. JSON validity check on `errors/errors_db.json`.
  2. PSScriptAnalyzer static analysis with 0 errors across all `.ps1` files.
  3. Full Pester test suite (`Invoke-Pester ./tests`) with 100% passing tests.
  4. Batch script syntax validation.
- **CODEOWNERS Approval**: At least **1 maintainer approval** (`@nkdhawan76`) is required on all changes to `scripts/`, `errors/`, and workflows before merging.

---

## 🔀 Branch Naming Conventions

When contributing code, please create a dedicated branch following these patterns:
- For fixing an existing error code or bug: `fix/<error-code>` (e.g., `fix/0x80070005`, `fix/wifi-adapter-drop`)
- For adding a new feature or diagnostic check: `feature/<name>` (e.g., `feature/bluetooth-le-scanner`, `feature/dism-repair-logging`)
- For documentation updates: `docs/<name>` (e.g., `docs/troubleshooting-guide`)

---

## 📋 Pull Request Requirements

Every Pull Request must satisfy the following criteria:

1. **OS Version Tested On**: Specify the exact Windows OS edition, architecture (x64/ARM64/x86), and build number.
2. **Error Code / Category**: Clearly identify which error code or hardware/network issue is being addressed.
3. **Before & After Log Output**: Provide console transcripts demonstrating the error before the fix and the successful resolution after running the script.
4. **New Error Code Requirement Checklist**:
   - Add entry to [`errors/errors_db.json`](file:///errors/errors_db.json) with description, category, fix script path, restart flag, and manual remediation steps.
   - Create the remediation PowerShell script `scripts/fix_<code/name>.ps1`.
   - If applicable (for network, Wi-Fi, Bluetooth, or DNS fixes), create the companion CMD fallback script `scripts/fix_<code/name>.bat` for Windows 7/8.1 legacy support.
   - Ensure the script is **idempotent** (can be re-run indefinitely without causing harm or error).
   - Ensure the script enforces administrative elevation checks.
   - Add matching unit/integration tests in `tests/`.
5. **No Hardcoded Secrets/Paths**: Never commit user-specific directory paths (`C:\Users\username\...`) or API tokens.

---

## 🛠️ Local Development & Testing

### 1. Clone the Repository
```powershell
git clone https://github.com/nkdhawan76/WindowsFixKit.git
Set-Location WindowsFixKit
```

### 2. Validate JSON Database
```powershell
Get-Content .\errors\errors_db.json -Raw | ConvertFrom-Json
```

### 3. Run PSScriptAnalyzer Linting
```powershell
Invoke-ScriptAnalyzer -Path .\scripts -Recurse -Severity Error, Warning
```

### 4. Run Pester Unit & Integration Test Suite
```powershell
Invoke-Pester -Path .\tests
```

### 5. Test Diagnostic Run in Scan-Only Mode
```powershell
.\scripts\diagnose.ps1 -ScanOnly
.\scripts\full_system_diagnosis.ps1 -OpenReport:$false
```

---

## 🏷️ Issue & PR Labels

| Label | Description |
| :--- | :--- |
| `good-first-issue` | Great for newcomers wanting to add simple error catalog entries or script fixes. |
| `error-fix` | Issues or PRs specifically resolving an error code or hardware drop. |
| `windows-7` | Specific to Windows 7 SP1 compatibility and command fallbacks (`netsh`, `sc`, `wmic`). |
| `windows-8.1` | Specific to Windows 8.1 environments. |
| `windows-10` | Specific to Windows 10 servicing stack and driver models. |
| `windows-11` | Specific to Windows 11 updates and modern networking interfaces. |
| `bug` | Unexpected behavior or script failure during diagnostic runs. |
| `documentation` | Improvements to guides, schema definitions, and how-it-works docs. |
