<div align="center">

# 🧰 WindowsFixKit

**Diagnostic and Auto-Fix Toolkit for Windows Update, Network, Wi-Fi, Bluetooth, DNS Errors, and Hardware System Health**  
*Supports Windows 7, 8.1, 10, and 11 — Powered by PowerShell 5.1/7+ and CMD Fallbacks*

[![Latest Release](https://img.shields.io/github/v/release/nkdhawan76/WindowsFixKit?color=3b82f6&logo=github)](https://github.com/nkdhawan76/WindowsFixKit/releases/latest)
[![CI](https://github.com/nkdhawan76/WindowsFixKit/actions/workflows/ci.yml/badge.svg)](https://github.com/nkdhawan76/WindowsFixKit/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![All Contributors](https://img.shields.io/github/all-contributors/nkdhawan76/WindowsFixKit?color=ee8449&style=flat-square)](#-contributors)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Platform](https://img.shields.io/badge/Platform-Windows%207%20%7C%208.1%20%7C%2010%20%7C%2011-0078D6.svg)](https://www.microsoft.com/windows)

</div>

---

## 💾 Direct Download (No Git Required)

For immediate troubleshooting on any PC without installing Git or cloning repositories:

[![Download Latest Release](https://img.shields.io/badge/Download-WindowsFixKit--latest.zip-success?style=for-the-badge&logo=windows)](https://github.com/nkdhawan76/WindowsFixKit/releases/latest/download/WindowsFixKit-latest.zip)

### How to Use the Downloaded Package:
1. **Download:** Click the button above to download `WindowsFixKit-latest.zip`.
2. **Extract:** Right-click the `.zip` file -> select **Extract All...**.
3. **Run:**
   - For Windows Update & Network repairs: Right-click `scripts\diagnose.ps1` -> **Run with PowerShell** (or run inside an elevated PowerShell terminal).
   - For Full Hardware & System Health Audit: Right-click `scripts\full_system_diagnosis.ps1` -> **Run with PowerShell**.

---

## 📖 Overview

**WindowsFixKit** is an open-source, non-destructive toolkit engineered to diagnose and automatically remediate common operating system corruptions, Windows Update failures, adapter disappearances, networking failures, and hardware bottlenecks.

Unlike generic cleanup utilities, **WindowsFixKit**:
- 🔍 **Harvests and Regex-Matches** real-time error logs (`WindowsUpdate.log`, `ReportingEvents.log`, Windows Event Viewer).
- 🩺 **Full System Diagnostic Engine**: Audits OS metadata, SSD/HDD SMART health & wear counters, physical RAM sticks & buffer allocation, battery health degradation, CPU thermal throttling, partition capacities, and startup bloat.
- 📊 **Generates Visual HTML Reports**: Automatically creates a modern, responsive HTML report saved directly to your Desktop (`WindowsFixKit-Report.html`).
- ⚙️ **Executes Idempotent Remediations** targeted specifically at the identified root cause.
- 🌐 **Features Dual-Engine Compatibility**: Uses modern PowerShell cmdlets on Windows 10/11 while providing rock-solid native CMD batch (`.bat`) fallbacks using `netsh`, `sc`, `ipconfig`, and `wmic` for Windows 7 and 8.1.
- 📋 **Delivers Transparent Reporting**: Produces a clean summary table detailing detected issues, fixes applied, and reboot requirements.

---

## 🖥️ Full System Diagnosis

WindowsFixKit includes an extensive system and hardware audit engine in `scripts/full_system_diagnosis.ps1` and modular diagnostic scripts under `scripts/diagnostics/`.

### What It Audits:
1. **OS & Hardware Info**: OS Edition, Version, Build Number, Architecture, System Model, Manufacturer, and Uptime via `Get-ComputerInfo` (with CIM fallback for Windows 7/8.1).
2. **Storage Health & SMART Data**: Storage media type (NVMe, SSD, HDD), Drive Wear %, Operating Temperature, and Uncorrected Read Errors via `Get-StorageReliabilityCounter` and `Get-PhysicalDisk`.
3. **Physical RAM & Allocation**: RAM stick vendors, clock speeds, capacities via `Win32_PhysicalMemory`, and live buffer headroom via `Get-Counter '\Memory\Available MBytes'` (flags when available memory < 10%).
4. **Battery Health & Capacity Loss**: Parses `powercfg /batteryreport` for Design Capacity vs Full Charge Capacity, calculating lifetime health % (flags when health < 60%).
5. **CPU Thermal Sensors**: Reads ACPI thermal zone temperatures via `root/wmi:MSAcpi_ThermalZoneTemperature` (flags when temperatures exceed 80°C/90°C).
6. **Disk Partition Capacity**: Scans all logical drives and flags any volume exceeding 90% utilization.
7. **Startup Application Bloat**: Enumerates startup apps via `Win32_StartupCommand` and Registry Run keys, alerting when > 15 autostart apps are active.

### Running Full System Diagnosis:
```powershell
# Run complete system diagnosis and automatically open Desktop HTML report
.\scripts\full_system_diagnosis.ps1

# Run individual diagnostic components independently:
.\scripts\diagnostics\check_os_info.ps1
.\scripts\diagnostics\check_disk_health.ps1
.\scripts\diagnostics\check_ram_health.ps1
.\scripts\diagnostics\check_battery_health.ps1
.\scripts\diagnostics\check_cpu_temp.ps1
.\scripts\diagnostics\check_startup_apps.ps1
```

### HTML Diagnostic Report Preview:
```text
+-------------------------------------------------------------------------------+
|  🧰 WindowsFixKit Diagnostic Report                      2026-08-30 23:25:00  |
+---------------------------------------+---------------------------------------+
|  🖥️ Operating System & Machine         |  🩺 System Health Executive Summary   |
|  OS Edition: Windows 11 Pro           |  Storage Integrity : Healthy          |
|  Build: 22631 (x64)                   |  Memory Status     : Healthy          |
|  Model: Dell XPS 15 / Intel i7        |  Battery Health    : 92.4% (Healthy)  |
|  Uptime: 2d 4h 15m                    |  CPU Thermals      : 44.2 °C (Normal) |
+---------------------------------------+---------------------------------------+
|  💾 Storage Health & Partitions       |  🧠 Physical Memory (RAM)             |
|  Disk #0: NVMe SSD 1024 GB (Wear: 4%) |  Total: 32.0 GB | Available: 22.4 GB  |
|  C: [====================      ] 72%  |  [============                  ] 30% |
+---------------------------------------+---------------------------------------+
|  🔋 Battery: 92.4% (Healthy)  |  🌡️ CPU: 44.2 °C  |  🚀 Startup Apps: 8 Items |
+-------------------------------------------------------------------------------+
```

---

## ⚡ Quick Start (Developers & Power Users)

### Option 1: Git Clone & Run (Recommended)

1. Open **PowerShell as Administrator** (Right-click PowerShell -> *Run as administrator*).
2. Clone the repository and navigate to the folder:
   ```powershell
   git clone https://github.com/nkdhawan76/WindowsFixKit.git
   Set-Location WindowsFixKit
   ```
3. Run the Windows Update & Network diagnostic engine:
   ```powershell
   .\scripts\diagnose.ps1
   ```
4. Or run the full hardware & system health diagnostic:
   ```powershell
   .\scripts\full_system_diagnosis.ps1
   ```

### Option 2: Run in Scan-Only Mode (No System Changes)
```powershell
.\scripts\diagnose.ps1 -ScanOnly
```

### Option 3: Run Individual Targeted Fixes
```powershell
# Windows Update permission error
.\scripts\fix_0x80070005.ps1

# Missing Wi-Fi adapter (PowerShell)
.\scripts\fix_wifi_missing.ps1

# Missing Wi-Fi adapter (Command Prompt / Windows 7 fallback)
.\scripts\fix_wifi_missing.bat

# Storage cleanup / space recovery
.\scripts\fix_storage_cleanup.ps1
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
│   │   └── release-zip.yml
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
├── CHANGELOG.md
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── LICENSE
├── README.md
└── VERSION
```

---

## 🔒 Security & Safety Guarantees

1. **100% Native**: Only uses official Windows system binaries (`dism.exe`, `sfc.exe`, `netsh.exe`, `icacls.exe`, `takeown.exe`, `sc.exe`, `pnputil.exe`, `powercfg.exe`).
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
