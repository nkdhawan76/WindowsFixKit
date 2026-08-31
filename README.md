<div align="center">

# 🧰 WindowsFixKit

**Diagnostic and repair toolkit for Windows Update, hardware health, Wi-Fi, Bluetooth, network stack, and DNS errors**

*Compatible with Windows 7, 8.1, 10, and 11 — Built with PowerShell, native CMD fallbacks, and automated test coverage*

[![Latest Release](https://img.shields.io/github/v/release/nkdhawan76/WindowsFixKit?color=3b82f6&logo=github)](https://github.com/nkdhawan76/WindowsFixKit/releases/latest)
[![Total Downloads](https://img.shields.io/github/downloads/nkdhawan76/WindowsFixKit/total?color=10b981&logo=windows)](https://github.com/nkdhawan76/WindowsFixKit/releases)
[![CI Build](https://github.com/nkdhawan76/WindowsFixKit/actions/workflows/ci.yml/badge.svg)](https://github.com/nkdhawan76/WindowsFixKit/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PowerShell Gallery](https://img.shields.io/badge/PSGallery-WindowsFixKit-blue.svg?logo=powershell)](https://www.powershellgallery.com/packages/WindowsFixKit)
[![Platform](https://img.shields.io/badge/Platform-Windows%207%20%7C%208.1%20%7C%2010%20%7C%2011-0078D6.svg)](https://www.microsoft.com/windows)

</div>

---

## 📦 Download

Download the portable zip archive for offline troubleshooting without installing Git or dependencies:

[![Download WindowsFixKit-latest.zip](https://img.shields.io/badge/Download-WindowsFixKit--latest.zip-success?style=for-the-badge&logo=windows)](https://github.com/nkdhawan76/WindowsFixKit/releases/latest/download/WindowsFixKit-latest.zip)

- **Current Release:** [v1.2.0 Release Notes](https://github.com/nkdhawan76/WindowsFixKit/releases/tag/v1.2.0)
- **Full Release History:** [GitHub Releases](https://github.com/nkdhawan76/WindowsFixKit/releases)

---

## ⚡ Quick Start

### Option 1: One-Click Menu (Recommended for Most Users)

1. Download [`WindowsFixKit-latest.zip`](https://github.com/nkdhawan76/WindowsFixKit/releases/latest/download/WindowsFixKit-latest.zip) and extract it.
2. Double-click **`WindowsFixKit.bat`** (or `run.bat`).
3. Accept the Administrator prompt (UAC).
4. Choose an action from the numbered menu:

```text
=================================================================
        WindowsFixKit - Windows Diagnostic and Auto-Repair
      DevSparks India | https://devsparksindia.com | 9521032268
=================================================================

  [1]  Full Hardware and System Health Diagnosis (Desktop HTML Report)
  [2]  Windows Update and Network Diagnostic + Auto-Fix (diagnose.ps1)
  [3]  Scan-Only Mode (Detect issues without making changes)
  [4]  Deep Junk & Temp Files Cleanup (%TEMP%, Prefetch, Recycle Bin, Cleanmgr)
  [5]  Deep RAM Cache & Memory Optimizer (Empty Working Sets, Trim Cache)
  [6]  Full Network and DNS Stack Reset (fix_network_reset)
  [7]  Fix Missing Wi-Fi Adapter (fix_wifi_missing)
  [8]  Fix Missing Bluetooth Service (fix_bluetooth_missing)
  [9]  Run Local CI Lint and Test Check (scripts\lint-check.ps1)
  [10] Exit
=================================================================
```

---

### Option 2: PowerShell Module

```powershell
# Install from PowerShell Gallery
Install-Module -Name WindowsFixKit -Scope CurrentUser

# Run full system diagnostics and export HTML report
Invoke-WindowsFixKit -DiagnosisType Full

# Run Windows Update and network diagnostics
Invoke-WindowsFixKit -DiagnosisType UpdateRepair
```

---

### Option 3: PowerShell CLI

```powershell
# Clone the repository
git clone https://github.com/nkdhawan76/WindowsFixKit.git
Set-Location WindowsFixKit

# Run the master diagnostic engine
.\scripts\diagnose.ps1

# Run full hardware diagnosis and export desktop HTML report
.\scripts\full_system_diagnosis.ps1
```

---

## 📖 What WindowsFixKit Does

WindowsFixKit scans and resolves common Windows Update failures, network drops, driver lockups, and hardware bottlenecks:

- 🔍 **Error Log Harvesting**: Parses `WindowsUpdate.log`, `ReportingEvents.log`, and Event Viewer logs with regex pattern matching to identify active HRESULT / NT error codes.
- 🩺 **Full System Diagnostics**: Audits hardware specs, disk SMART health counters, RAM buffers, battery degradation, CPU thermals, drive capacities, and startup programs.
- 📊 **Exportable Reports**: Creates a clean, styled HTML report saved directly to your Desktop (`WindowsFixKit-Report.html`).
- ⚙️ **Targeted Fixes**: Runs isolated scripts focused specifically on the detected problem, creating backups instead of blindly deleting files.
- 🌐 **Backward Compatibility**: Uses native PowerShell cmdlets on Windows 10/11 with CMD batch (`.bat`) fallbacks (`netsh`, `sc`, `ipconfig`, `wmic`) for Windows 7 and 8.1.
- 📋 **Summary Reporting**: Displays a summary table of issues found, actions taken, and reboot requirements.

---

## 🖥️ System Health Diagnostics

Run `scripts/full_system_diagnosis.ps1` to perform a hardware and system health audit, or execute individual diagnostic scripts directly:

| Subsystem | Diagnostic Script | Checks & Metrics |
| :--- | :--- | :--- |
| **System Info** | [`check_os_info.ps1`](scripts/diagnostics/check_os_info.ps1) | OS edition, version, build number, architecture, model, manufacturer, and uptime. |
| **Storage & SMART** | [`check_disk_health.ps1`](scripts/diagnostics/check_disk_health.ps1) | NVMe/SSD/HDD media types, drive wear %, operating temperature, read errors, and partition free space. |
| **Memory (RAM)** | [`check_ram_health.ps1`](scripts/diagnostics/check_ram_health.ps1) | RAM stick vendors, clock speeds, capacities, and active buffer headroom (flags when free RAM < 10%). |
| **Battery Health** | [`check_battery_health.ps1`](scripts/diagnostics/check_battery_health.ps1) | Design capacity vs full charge capacity, degradation %, and AC power state (flags when health < 60%). |
| **CPU Thermals** | [`check_cpu_temp.ps1`](scripts/diagnostics/check_cpu_temp.ps1) | ACPI thermal zone diode temperature readings (flags when temp > 80°C/90°C). |
| **Startup Apps** | [`check_startup_apps.ps1`](scripts/diagnostics/check_startup_apps.ps1) | Scans autostart applications in registry and WMI (flags when > 15 apps are active). |

---

## 📋 Supported Error Codes & Remediations

| Error Code / Category | Subsystem | Description | Fix Script (`.ps1`) | Fallback (`.bat`) | Reboot? |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **`0x80070005`** | Windows Update | Access Denied - ACL & permission issues on `WinSxS` / `SoftwareDistribution` | [`fix_0x80070005.ps1`](scripts/fix_0x80070005.ps1) | — | Yes |
| **`0x8024402c`** | Windows Update | Update Server Unreachable - Proxy misconfiguration or corrupt update cache | [`fix_0x8024402c.ps1`](scripts/fix_0x8024402c.ps1) | — | No |
| **`0x8024402f`** | Windows Update | Update Install Failure Loop - Corrupted datastore or catalog database | [`fix_0x8024402f.ps1`](scripts/fix_0x8024402f.ps1) | — | Yes |
| **`0x80072EFD`** | Windows Update | Server Connection Interrupted - TLS protocol mismatch or firewall block | [`fix_0x80072EFD.ps1`](scripts/fix_0x80072EFD.ps1) | — | No |
| **`0xc1900101`** | Windows Update | Feature Update Rollback - Driver conflicts, DISM/SFC system corruptions | [`fix_0xc1900101.ps1`](scripts/fix_0xc1900101.ps1) | — | Yes |
| **`0x800f0922`** | Windows Update | SSU / .NET Failure - System Partition (ESP) space limit or active VPN filter | [`fix_0x800f0922.ps1`](scripts/fix_0x800f0922.ps1) | — | Yes |
| **`wifi_missing_post_update`** | Hardware / Wi-Fi | Wi-Fi adapter or tray icon disappears after an update or sleep cycle | [`fix_wifi_missing.ps1`](scripts/fix_wifi_missing.ps1) | [`fix_wifi_missing.bat`](scripts/fix_wifi_missing.bat) | No |
| **`bluetooth_missing_post_update`** | Hardware / Bluetooth | Bluetooth service (`bthserv`) disabled or radio device missing post-update | [`fix_bluetooth_missing.ps1`](scripts/fix_bluetooth_missing.ps1) | [`fix_bluetooth_missing.bat`](scripts/fix_bluetooth_missing.bat) | No |
| **`network_no_internet`** | Networking | Adapter connected to LAN but displays "No Internet Access" | [`fix_network_reset.ps1`](scripts/fix_network_reset.ps1) | [`fix_network_reset.bat`](scripts/fix_network_reset.bat) | Yes |
| **`dns_not_resolving`** | Networking / DNS | Domain lookups fail while direct IP pings succeed | [`fix_dns.ps1`](scripts/fix_dns.ps1) | [`fix_dns.bat`](scripts/fix_dns.bat) | No |
| **`hdd_ssd_unhealthy`** | Hardware / Storage | Physical disk wear >80%, SMART warnings, or read error spikes | [`fix_disk_errors.ps1`](scripts/fix_disk_errors.ps1) | — | Yes |
| **`ram_error_detected`** | Hardware / Memory | Available RAM < 10% or memory pool exhaustion | [`fix_ram_cache.ps1`](scripts/fix_ram_cache.ps1) | — | No |
| **`battery_degraded`** | Hardware / Power | Full charge battery capacity degraded < 60% of original design | [`fix_battery_optimization.ps1`](scripts/fix_battery_optimization.ps1) | — | No |
| **`cpu_overheating`** | Hardware / CPU | Core temperature > 80°C under load / thermal throttling | [`fix_cpu_thermal.ps1`](scripts/fix_cpu_thermal.ps1) | — | No |
| **`storage_almost_full`** | Storage / Partitions | Logical drive capacity > 90% full | [`fix_storage_cleanup.ps1`](scripts/fix_storage_cleanup.ps1) | — | No |
| **`startup_bloat`** | System / Startup | More than 15 startup apps active, causing slow boot times | [`fix_startup_bloat.ps1`](scripts/fix_startup_bloat.ps1) | — | No |

---

## 🏗️ Repository Architecture

```text
WindowsFixKit/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   └── new_error_request.md
│   ├── workflows/
│   │   ├── ci.yml
│   │   ├── version-bump.yml
│   │   ├── release-zip.yml
│   │   └── publish-psgallery.yml
│   ├── CODEOWNERS
│   └── PULL_REQUEST_TEMPLATE.md
├── docs/
│   └── how-it-works.md
├── errors/
│   └── errors_db.json
├── reports/
│   └── report_template.html
├── scripts/
│   ├── full_system_diagnosis.ps1
│   ├── diagnose.ps1
│   ├── lint-check.ps1
│   ├── diagnostics/
│   │   ├── check_os_info.ps1
│   │   ├── check_disk_health.ps1
│   │   ├── check_ram_health.ps1
│   │   ├── check_battery_health.ps1
│   │   ├── check_cpu_temp.ps1
│   │   └── check_startup_apps.ps1
│   ├── fix_0x80070005.ps1
│   ├── fix_0x8024402c.ps1
│   ├── fix_0x8024402f.ps1
│   ├── fix_0x80072EFD.ps1
│   ├── fix_0xc1900101.ps1
│   ├── fix_0x800f0922.ps1
│   ├── fix_wifi_missing.ps1 + fix_wifi_missing.bat
│   ├── fix_bluetooth_missing.ps1 + fix_bluetooth_missing.bat
│   ├── fix_network_reset.ps1 + fix_network_reset.bat
│   ├── fix_dns.ps1 + fix_dns.bat
│   ├── fix_storage_cleanup.ps1
│   ├── fix_startup_bloat.ps1
│   ├── fix_disk_errors.ps1
│   ├── fix_ram_cache.ps1
│   ├── fix_cpu_thermal.ps1
│   └── fix_battery_optimization.ps1
├── tests/
│   ├── Diagnostics.Tests.ps1
│   ├── Scripts.Tests.ps1
│   └── Validate-ErrorsDb.Tests.ps1
├── .all-contributorsrc
├── .gitignore
├── .markdownlint.json
├── CHANGELOG.md
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── LICENSE
├── README.md
├── run.bat
├── VERSION
├── WindowsFixKit.bat
├── WindowsFixKit.psd1
└── WindowsFixKit.psm1
```

---

## 🔒 Safety & Design Principles

1. **Native Binaries Only**: Uses built-in Windows system tools (`dism.exe`, `sfc.exe`, `netsh.exe`, `icacls.exe`, `takeown.exe`, `sc.exe`, `pnputil.exe`, `powercfg.exe`).
2. **Idempotency**: All scripts can be re-run safely without producing unintended side effects.
3. **Safe Backups**: Corrupted update folders and cache directories are rotated with `.bak` extensions instead of being deleted.

For in-depth architectural details, see [How It Works](docs/how-it-works.md).

---

## 🤝 Contributing

Contributions and new error code mappings are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting a Pull Request.

Run the local test and lint suite before pushing changes:

```powershell
.\scripts\lint-check.ps1
```

---

## 👨‍💻 Maintained by & Support

**Nikil Dhawan & DevSparks India**
- 🌐 Website: [devsparksindia.com](https://devsparksindia.com/)
- 📞 Phone / WhatsApp: [+91 9521032268](tel:+919521032268)
- ✉️ Email: [devsparksindia@gmail.com](mailto:devsparksindia@gmail.com)
- 🐙 GitHub: [@nkdhawan76](https://github.com/nkdhawan76)
- 🧰 Repository: [WindowsFixKit](https://github.com/nkdhawan76/WindowsFixKit)

---

## 👥 Contributors

Thanks to the contributors who have improved WindowsFixKit ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

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

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
