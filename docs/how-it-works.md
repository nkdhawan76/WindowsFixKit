# How WindowsFixKit Works

**WindowsFixKit** is an open-source diagnostic and automated repair toolkit designed to remediate Windows Update failures, hardware device disappearances (Wi-Fi, Bluetooth), TCP/IP / DNS network corruptions, and system health bottlenecks across Windows 7, 8.1, 10, and 11.

---

## High-Level Architecture

```mermaid
flowchart TD
    subgraph Windows Update & Network Diagnostics
        A[User Launches diagnose.ps1 as Admin] --> B{Elevation Check}
        B -- Not Admin --> C[Exit with Guidance Message]
        B -- Is Admin --> D[Load errors/errors_db.json]
        
        D --> E[Phase 1: Windows Update Log Analysis]
        E -->|Regex 0x[0-9A-Fa-f]{8}| E1[Match Error in errors_db.json]
        E1 -->|Found| E2[Run fix_0x*.ps1]
        
        D --> F[Phase 2: IP Connectivity Test]
        F -->|Fail| F1[Run fix_network_reset.ps1]
        
        D --> G[Phase 3: Wi-Fi Hardware & Service Test]
        G -->|Fail| G1[Run fix_wifi_missing.ps1]
        
        D --> H[Phase 4: Bluetooth Service & Radio Test]
        H -->|Fail| H1[Run fix_bluetooth_missing.ps1]
        
        D --> I[Phase 5: DNS Name Resolution Test]
        I -->|Fail| I1[Run fix_dns.ps1]
    end

    subgraph Full System Diagnosis
        S[User Launches full_system_diagnosis.ps1] --> S1[OS & Hardware Specs]
        S --> S2[Storage Media & SMART Counters]
        S --> S3[RAM Utilization & Hardware Modules]
        S --> S4[Battery Capacity & Degradation]
        S --> S5[CPU Sensor Thermals]
        S --> S6[Startup Autostart Registry Bloat]
        S1 & S2 & S3 & S4 & S5 & S6 --> S7[Render WindowsFixKit-Report.html]
    end
```

---

## 1. Diagnostic Engine (`diagnose.ps1`)

The diagnostic engine performs a 5-stage health sweep:

### Phase 1: Windows Update Log Harvesting & Regex Matching

- **Source Inspection**: Reads the most recent transactions from `%SystemRoot%\SoftwareDistribution\ReportingEvents.log`, the `Microsoft-Windows-WindowsUpdateClient` event log provider, and `Get-WindowsUpdateLog`.
- **Pattern Extraction**: Scans text streams using regex `0x[0-9A-Fa-f]{8}` for active hexadecimal Windows NT / HRESULT error codes.
- **Catalog Lookup**: Matches discovered codes against `errors/errors_db.json`.

### Phase 2: Gateway & IP Reachability

- Performs low-level ICMP ping tests to `8.8.8.8` via `.NET System.Net.NetworkInformation.Ping` to verify whether the packet transmission pipeline is operational without relying on DNS.

### Phase 3: Wireless Adapter & Service Audit

- Audits Plug and Play (`PnP`) network devices via `Get-PnpDevice -Class Net` and `Get-NetAdapter`.
- Verifies the state of `WlanSvc` (WLAN AutoConfig). If an adapter is disabled or disconnected due to a driver migration glitch post-update, it flags for remediation.

### Phase 4: Bluetooth Subsystem Audit

- Checks status and start configuration for `bthserv` (Bluetooth Support Service) and `BTAGService` (Bluetooth Audio Gateway).
- Validates Bluetooth PnP radios under the `{e0cbf06c-cd8b-4647-bb8a-263b43f0f974}` class GUID.

### Phase 5: Domain Name Resolution (DNS)

- Performs asynchronous queries against root authority domains (`microsoft.com`, `google.com`) using `.NET System.Net.Dns` and `Resolve-DnsName`.

---

## 2. Full System Diagnostic Subsystem (`full_system_diagnosis.ps1`)

The hardware and system diagnosis module queries ring-0 and WMI/CIM kernel telemetry across 6 primary domains:

| Subsystem | Underlying Cmdlet / Method | Thresholds & Checks |
| :--- | :--- | :--- |
| **OS & Hardware Specs** | `Get-ComputerInfo` / `Win32_OperatingSystem` | Evaluates OS build version, architecture, BIOS date, and uptime. |
| **Storage & SMART** | `Get-PhysicalDisk` / `Get-StorageReliabilityCounter` | Identifies NVMe/SSD/HDD media types; flags wear >80%, uncorrected read errors, or volumes >90% full. |
| **Memory (RAM)** | `Win32_PhysicalMemory` / `Get-Counter` | Audits module clock speeds and part numbers; flags when available RAM is < 10% of total capacity. |
| **Battery Health** | `powercfg /batteryreport` | Extracts Design Capacity vs Full Charge Capacity; flags degradation <60%. |
| **CPU Thermals** | `root/wmi:MSAcpi_ThermalZoneTemperature` | Converts tenths of Kelvin to Celsius; flags warnings >80°C and critical states >90°C. |
| **Startup Bloat** | `Win32_StartupCommand` & Registry Run Keys | Scans autostart programs; flags excessive bloat when >15 items are detected. |

All results are formatted into a live console summary table and exported to a responsive, dark-mode HTML report saved directly to `$HOME\Desktop\WindowsFixKit-Report.html`.

---

## 3. Remediations & Subsystems

### Windows Update Subsystem

Windows Update relies on interdependent subsystems that frequently get trapped in corrupted states:

1. **Background Intelligent Transfer Service (BITS)**: Handles background downloads and throttling.
2. **Windows Update Service (`wuauserv`)**: Evaluates patch applicability and schedules installations.
3. **Cryptographic Services (`cryptSvc`)**: Validates Authenticode signatures and catalog hashes under `catroot2`.
4. **SoftwareDistribution Store (`%SystemRoot%\SoftwareDistribution`)**: Local cache of downloaded update payloads and transactional metadata.
5. **Component-Based Servicing (`CBS` / `WinSxS`)**: Manages side-by-side component versions and servicing manifests.

| Error Code | Root Cause | Remediation Mechanism |
| :--- | :--- | :--- |
| `0x80070005` | Access Denied / ACL corruption | Takes ownership (`takeown`) and resets inherited ACLs (`icacls`) granting SYSTEM and Administrators full control over `SoftwareDistribution` and registry keys. |
| `0x8024402c` | Proxy / DNS routing failure | Purges WinHTTP proxy via `netsh winhttp reset proxy`, clears temporary caches, flushes DNS, and resets stale WSUS registry pointers. |
| `0x8024402f` | Datastore / catalog loop failure | Stops update services, rotates `SoftwareDistribution` and `Catroot2` to backup paths, re-registers COM DLLs (`wuapi.dll`, `atl.dll`, `wups.dll`), and restarts daemons. |
| `0x80072EFD` | Endpoint connection failure | Enforces TLS 1.2 / 1.3 in Schannel, activates .NET strong cryptography, and resets socket configurations. |
| `0xc1900101` | Upgrade rollback / driver clash | Purges `$WINDOWS.~BT` staging structures, executes DISM image servicing (`/RestoreHealth`), and initiates SFC scans (`sfc /scannow`). |
| `0x800f0922` | .NET / Partition space / VPN clash | Restores .NET Framework 3.5 features via DISM, purges CBS logs, and alerts on active VPN proxy interfaces. |
| `storage_almost_full` | High disk utilization (>90%) | Purges `%temp%`, Windows temp, Delivery Optimization caches, empties Recycle Bin, and runs `cleanmgr`. |
| `startup_bloat` | Excessive startup delay | Prunes dead registry entries in `Run` keys and provides guided disablement of high-impact launchers. |
| `hdd_ssd_unhealthy` | Drive wear / bad sectors | Executes non-destructive online filesystem scan (`chkdsk /scan`) and triggers SSD TRIM re-optimization. |
| `ram_error_detected` | Memory buffer exhaustion | Trims system working sets, calls garbage collector, and verifies pagefile settings. |
| `cpu_overheating` | Thermal throttling / thermal runaway | Enforces active cooling policy and sets maximum processor state to 99% to eliminate thermal boost spikes. |
| `battery_degraded` | Significant battery wear | Enforces battery saver power policies and optimizes monitor sleep timeouts. |

---

## 4. Idempotency & Safety Guarantees

Every script in WindowsFixKit adheres to strict reliability rules:

1. **Safe to Re-Run**: Executing any script multiple times produces the same stable state without side effects.
2. **Non-Destructive Backups**: Rather than permanently deleting database folders, components are renamed (`.bak`) to prevent data loss.
3. **No Unapproved Third-Party Executables**: Relies exclusively on native signed Windows binaries (`dism.exe`, `sfc.exe`, `netsh.exe`, `takeown.exe`, `icacls.exe`, `regsvr32.exe`, `sc.exe`, `powercfg.exe`).
