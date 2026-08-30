# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
