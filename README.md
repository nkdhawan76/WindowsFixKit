<div align="center">

# 🧰 WindowsFixKit

**Diagnostic and Auto-Fix Toolkit for Windows Update, Network, Wi-Fi, Bluetooth, and DNS Errors**  
*Supports Windows 7, 8.1, 10, and 11 — Powered by PowerShell 5.1/7+ and CMD Fallbacks*

[![CI](https://github.com/nkdhawan76/WindowsFixKit/actions/workflows/ci.yml/badge.svg)](https://github.com/nkdhawan76/WindowsFixKit/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![All Contributors](https://img.shields.io/github/all-contributors/nkdhawan76/WindowsFixKit?color=ee8449&style=flat-square)](#-contributors)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Platform](https://img.shields.io/badge/Platform-Windows%207%20%7C%208.1%20%7C%2010%20%7C%2011-0078D6.svg)](https://www.microsoft.com/windows)

</div>

---

## 📖 Overview

**WindowsFixKit** is an open-source, non-destructive toolkit engineered to diagnose and automatically remediate common operating system corruptions, Windows Update failures, adapter disappearances, and networking failures.

Unlike generic cleanup utilities, **WindowsFixKit**:
- 🔍 **Harvests and Regex-Matches** real-time error logs (`WindowsUpdate.log`, `ReportingEvents.log`, Windows Event Viewer).
- ⚙️ **Executes Idempotent Remediations** targeted specifically at the identified root cause.
- 🌐 **Features Dual-Engine Compatibility**: Uses modern PowerShell cmdlets on Windows 10/11 while providing rock-solid native CMD batch (`.bat`) fallbacks using `netsh`, `sc`, `ipconfig`, and `wmic` for Windows 7 and 8.1.
- 📊 **Delivers Transparent Reporting**: Produces a clean summary table detailing detected issues, fixes applied, and reboot requirements.

---

## ⚡ Quick Start

### Option 1: Git Clone & Run (Recommended)

1. Open **PowerShell as Administrator** (Right-click PowerShell -> *Run as administrator*).
2. Clone the repository and navigate to the folder:
   ```powershell
   git clone https://github.com/nkdhawan76/WindowsFixKit.git
   Set-Location WindowsFixKit
   ```
3. Run the diagnostic engine:
   ```powershell
   .\scripts\diagnose.ps1
   ```

### Option 2: Run in Scan-Only Mode (No System Changes)
```powershell
.\scripts\diagnose.ps1 -ScanOnly
```

### Option 3: Run Individual Targeted Fixes
If you already know the specific error code or issue on your machine, you can run its standalone fix directly:
```powershell
# Windows Update permission error
.\scripts\fix_0x80070005.ps1

# Missing Wi-Fi adapter (PowerShell)
.\scripts\fix_wifi_missing.ps1

# Missing Wi-Fi adapter (Command Prompt / Windows 7 fallback)
.\scripts\fix_wifi_missing.bat
```

---

## 📋 Supported Error Codes & Remediations

| Error Code / Category | Subsystem | Description | Fix Script (`.ps1`) | Fallback (`.bat`) | Reboot? |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **`0x80070005`** | Windows Update | Access Denied - ACL & permission corruptions on `WinSxS` / `SoftwareDistribution` | [`fix_0x80070005.ps1`](scripts/fix_0x80070005.ps1) | — | Yes |
| **`0x8024402c`** | Windows Update | Update Server Unreachable - Proxy misconfiguration or junk update cache | [`fix_0x8024402c.ps1`](scripts/fix_0x8024402c.ps1) | — | No |
| **`0x8024402f`** | Windows Update | Update Install Failure Loop - Corrupted datastore or catalog database | [`fix_0x8024402f.ps1`](scripts/fix_0x8024402f.ps1) | — | Yes |
| **`0x80072EFD`** | Windows Update | Server Connection Interrupted - TLS protocol mismatch or firewall lock | [`fix_0x80072EFD.ps1`](scripts/fix_0x80072EFD.ps1) | — | No |
| **`0xc1900101`** | Windows Update | Feature Update Rollback - Incompatible drivers, DISM/SFC corruption | [`fix_0xc1900101.ps1`](scripts/fix_0xc1900101.ps1) | — | Yes |
| **`0x800f0922`** | Windows Update | SSU / .NET Failure - System Partition (ESP) space limit or active VPN filter | [`fix_0x800f0922.ps1`](scripts/fix_0x800f0922.ps1) | — | Yes |
| **`wifi_missing_post_update`** | Hardware / Wi-Fi | Wi-Fi adapter/tray icon disappears after a Windows update or sleep cycle | [`fix_wifi_missing.ps1`](scripts/fix_wifi_missing.ps1) | [`fix_wifi_missing.bat`](scripts/fix_wifi_missing.bat) | No |
| **`bluetooth_missing_post_update`** | Hardware / Bluetooth | Bluetooth toggle/service (`bthserv`) missing or disabled post-update | [`fix_bluetooth_missing.ps1`](scripts/fix_bluetooth_missing.ps1) | [`fix_bluetooth_missing.bat`](scripts/fix_bluetooth_missing.bat) | No |
| **`network_no_internet`** | Networking | Adapter connected to LAN but displays "No Internet Access" | [`fix_network_reset.ps1`](scripts/fix_network_reset.ps1) | [`fix_network_reset.bat`](scripts/fix_network_reset.bat) | Yes |
| **`dns_not_resolving`** | Networking / DNS | Domain lookups fail, websites do not load, IP ping succeeds | [`fix_dns.ps1`](scripts/fix_dns.ps1) | [`fix_dns.bat`](scripts/fix_dns.bat) | No |

---

## 🏗️ Repository Architecture

```text
WindowsFixKit/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   └── new_error_request.md
│   ├── workflows/
│   │   └── ci.yml
│   └── PULL_REQUEST_TEMPLATE.md
├── docs/
│   └── how-it-works.md
├── errors/
│   └── errors_db.json
├── scripts/
│   ├── diagnose.ps1
│   ├── fix_0x80070005.ps1
│   ├── fix_0x8024402c.ps1
│   ├── fix_0x8024402f.ps1
│   ├── fix_0x80072EFD.ps1
│   ├── fix_0xc1900101.ps1
│   ├── fix_0x800f0922.ps1
│   ├── fix_wifi_missing.ps1
│   ├── fix_wifi_missing.bat
│   ├── fix_bluetooth_missing.ps1
│   ├── fix_bluetooth_missing.bat
│   ├── fix_network_reset.ps1
│   ├── fix_network_reset.bat
│   ├── fix_dns.ps1
│   └── fix_dns.bat
├── .all-contributorsrc
├── .gitignore
├── CHANGELOG.md
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

---

## 🔒 Security & Safety Guarantees

1. **100% Native**: Only uses official Windows system binaries (`dism.exe`, `sfc.exe`, `netsh.exe`, `icacls.exe`, `takeown.exe`, `sc.exe`, `pnputil.exe`).
2. **Safe Re-Runs**: Every script is written to be strictly idempotent.
3. **No Blind Deletions**: Corrupt datastores are safely backed up with `.bak` extensions rather than erased without trace.

For an in-depth explanation of diagnostic mechanics and subsystem handling, read [How It Works](docs/how-it-works.md).

---

## 🤝 Contributing

Contributions are warmly welcomed! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for branch naming standards, testing requirements, and PR review checklists.

To propose a new error code fix, use our [New Error Code Request Template](https://github.com/nkdhawan76/WindowsFixKit/issues/new?template=new_error_request.md).

---

## 👥 Contributors

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/nkdhawan76"><img src="https://avatars.githubusercontent.com/nkdhawan76" width="100px;" alt="Nikil Dhawan"/><br /><sub><b>Nikil Dhawan</b></sub></a><br /><a href="https://github.com/nkdhawan76/WindowsFixKit/commits?author=nkdhawan76" title="Code">💻</a> <a href="https://github.com/nkdhawan76/WindowsFixKit/commits?author=nkdhawan76" title="Documentation">📖</a> <a href="#maintenance-nkdhawan76" title="Maintenance">🚧</a> <a href="#infra-nkdhawan76" title="Infrastructure">🚇</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!

---

## 📄 License

This project is licensed under the [MIT License](LICENSE) - see the [LICENSE](LICENSE) file for details.
