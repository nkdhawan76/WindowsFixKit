# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.2] - 2026-08-31

### Fixed
- **Batch Redirection Syntax Error (`> was unexpected at this time`)**: Replaced unescaped `echo [>>>]` banner messages with clean, safe `echo [INFO]` across all option handlers in `WindowsFixKit.bat`, eliminating instant CMD process termination when selecting any menu option.

## [1.1.1] - 2026-08-31

### Fixed
- **Launcher Elevation & Path Space Bug**: Fixed CMD crash when launcher path contains spaces (`Start-Process -FilePath '%~f0' -Verb RunAs`) across `WindowsFixKit.bat` and all fallback `.bat` scripts.
- **Menu Option 1 Crash & Window Flash**: Fixed `full_system_diagnosis.ps1` premature termination and detached window spawn, allowing full diagnostics and HTML report generation to execute inline seamlessly.
- **Report Parameter Handling**: Standardized `-NoOpenReport` switch and added robust error handling for browser launch.

## [1.1.0] - 2026-08-30

### Added

- **Master Full System Diagnosis Engine (`full_system_diagnosis.ps1`)**:
  - Comprehensive orchestration of hardware telemetry, storage health, RAM buffers, battery degradation, CPU thermals, partition usage, and startup bloat.
  - Automatically exports a styled, responsive HTML report (`WindowsFixKit-Report.html`) with color-coded status badges directly to the user's Desktop.
  - Formats real-time summary status tables in console output.
- **Modular Hardware & Health Diagnostics (`scripts/diagnostics/`)**:
  - `check_os_info.ps1`: OS edition, build number, architecture, model, manufacturer, and uptime.
  - `check_disk_health.ps1`: NVMe/SSD/HDD media types, SMART counters (wear %, temperature, read errors), and partition threshold audits.
  - `check_ram_health.ps1`: Physical memory module vendors, clock speeds, capacities, and active RAM buffer calculation.
  - `check_battery_health.ps1`: Automated `powercfg /batteryreport` generation, parsing design vs full charge capacity, degradation % tracking, and desktop AC power detection.
  - `check_cpu_temp.ps1`: ACPI thermal zone temperature polling via WMI with fallback guidance.
  - `check_startup_apps.ps1`: Startup impact analysis from `Win32_StartupCommand` and Registry Run keys.
- **New System Health Remediations**:
  - `fix_storage_cleanup.ps1`: Temp directories, Delivery Optimization, and automated cleanmgr pass.
  - `fix_startup_bloat.ps1`: Broken startup registry pruning and startup app management.
  - `fix_disk_errors.ps1`: Filesystem integrity checks and SSD TRIM volume optimization.
  - `fix_ram_cache.ps1`: Garbage collection, working set trimming, and pagefile verification.
  - `fix_cpu_thermal.ps1`: CPU power plan processor limits and active cooling policy.
  - `fix_battery_optimization.ps1`: Battery saver thresholds and sleep/standby timeout alignment.
- **Expanded Error Catalog (`errors/errors_db.json`)**:
  - Added mappings for `hdd_ssd_unhealthy`, `ram_error_detected`, `battery_degraded`, `cpu_overheating`, `storage_almost_full`, and `startup_bloat`.

## [1.0.0] - 2026-08-30

### Added

- **Diagnostic Engine (`diagnose.ps1`)**:
  - Automated detection of Windows Update error codes via WindowsUpdate.log, ReportingEvents.log, and Windows Event logs.
  - Independent health diagnostic sweeps for Internet connectivity, Wi-Fi adapters, Bluetooth service/radios, and DNS resolution.
  - Automated remediation trigger system with pre-execution validation and detailed execution reports.
  - Comprehensive summary status table output with restart requirements.
  - Cross-version support for PowerShell 5.1 and PowerShell 7+.
- **Windows Update Fix Scripts**:
  - `fix_0x80070005.ps1`: Resolves access denied / permission errors on `WinSxS` and `SoftwareDistribution`.
  - `fix_0x8024402c.ps1`: Cleans proxy misconfigurations and invalid update cache structures.
  - `fix_0x8024402f.ps1`: Full reset of core Windows Update components (BITS, wuauserv, cryptsvc, Catroot2).
  - `fix_0x80072EFD.ps1`: Resolves Windows Update server connection & WinHTTP transport issues.
  - `fix_0xc1900101.ps1`: Clears feature update rollback conflicts, runs DISM image health repair, and scans system integrity.
  - `fix_0x800f0922.ps1`: Repairs .NET Framework components, checks system partition space, and verifies secure boot/VPN isolation.
- **Hardware & Network Remediation Subsystems (Dual PowerShell & Batch Fallbacks)**:
  - `fix_wifi_missing.ps1` & `fix_wifi_missing.bat`: Re-enables disabled Wi-Fi adapters, restarts WLAN AutoConfig service, and rescans device tree.
  - `fix_bluetooth_missing.ps1` & `fix_bluetooth_missing.bat`: Restarts Bluetooth support service, enables audio gateway, and triggers PnP rediscovery.
  - `fix_network_reset.ps1` & `fix_network_reset.bat`: Performs full Winsock catalog reset, TCP/IP stack re-initialization, and DHCP lease refresh.
  - `fix_dns.ps1` & `fix_dns.bat`: Flushes resolver cache, re-registers DNS, and configures resilient public DNS fallbacks (Cloudflare/Google).
- **Extensible Database**:
  - `errors/errors_db.json`: JSON schema linking error codes/categories to script paths, descriptions, and manual instructions.
- **CI/CD & Repository Infrastructure**:
  - GitHub Actions workflow running `PSScriptAnalyzer` linting and syntax validations.
  - Issue templates for bug reports and new error requests.
  - Comprehensive documentation (`README.md`, `docs/how-it-works.md`, `CONTRIBUTING.md`).
