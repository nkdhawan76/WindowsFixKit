# Contributing to WindowsFixKit

Thank you for contributing to **WindowsFixKit**! Our mission is to provide an open-source, reliable, and transparent diagnostic and auto-repair toolkit for Windows Update, networking, and hardware issues across Windows 7, 8.1, 10, and 11.

---

## 🔀 Branch Naming Conventions

When contributing code, please create a dedicated branch following these patterns:
- For fixing an existing error code or bug: `fix/<error-code>` (e.g., `fix/0x80070005`, `fix/wifi-adapter-drop`)
- For adding a new feature or diagnostic check: `feature/<name>` (e.g., `feature/bluetooth-le-scanner`, `feature/dism-repair-logging`)
- For documentation updates: `docs/<name>` (e.g., `docs/troubleshooting-guide`)

---

## 📋 Pull Request Requirements

Every Pull Request must satisfy the following criteria before being considered for review:

1. **OS Version Tested On**: Specify the exact Windows OS edition, architecture (x64/ARM64/x86), and build number.
2. **Error Code / Category**: Clearly identify which error code or hardware/network issue is being addressed.
3. **Before & After Log Output**: Provide console transcripts demonstrating the error before the fix and the successful resolution after running the script.
4. **New Error Code Requirement Checklist**:
   - Add entry to [`errors/errors_db.json`](file:///errors/errors_db.json) with description, category, fix script path, restart flag, and manual remediation steps.
   - Create the remediation PowerShell script `scripts/fix_<code/name>.ps1`.
   - If applicable (for network, Wi-Fi, Bluetooth, or DNS fixes), create the companion CMD fallback script `scripts/fix_<code/name>.bat` for Windows 7/8.1 legacy support.
   - Ensure the script is **idempotent** (can be re-run indefinitely without causing harm or error).
   - Ensure the script enforces administrative elevation checks.
5. **Code Style & Linting**: All `.ps1` files must pass `PSScriptAnalyzer` with zero errors.
6. **Review Policy**: At least **1 maintainer approval** (`@nkdhawan76`) is strictly required before any PR can be merged.

---

## 🏷️ Issue & PR Labels

We use standard repository labels to categorize tasks and target environments:

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

---

## 🛠️ Local Development & Testing

### 1. Fork & Clone
```bash
git clone https://github.com/nkdhawan76/WindowsFixKit.git
cd WindowsFixKit
```

### 2. Validate JSON Database
```powershell
Get-Content .\errors\errors_db.json -Raw | ConvertFrom-Json
```

### 3. Run PSScriptAnalyzer
```powershell
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
Invoke-ScriptAnalyzer -Path .\scripts -Recurse
```

### 4. Test Diagnostic Run in Scan-Only Mode
```powershell
.\scripts\diagnose.ps1 -ScanOnly
```
