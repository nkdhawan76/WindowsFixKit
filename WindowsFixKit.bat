@echo off
:: ============================================================================
::  WindowsFixKit - Master One-Click Launcher
::  Target: Windows 7, 8.1, 10, 11
::  DevSparks India | https://devsparksindia.com | 9521032268
:: ============================================================================

title WindowsFixKit - System Diagnostic and Repair Toolkit
color 0B

:: Check for Administrator Privileges and Self-Elevate
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo =================================================================
    echo   [!] Administrative Privileges Required
    echo   Requesting User Account Control elevation...
    echo =================================================================
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: Ensure working directory is the script directory
cd /d "%~dp0"

:: Disable CMD QuickEdit Mode to prevent script freeze on mouse click
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$h=[System.IntPtr](Get-Process -Id $PID).MainWindowHandle;$m=Get-ItemProperty -Path 'HKCU:\Console' -Name 'QuickEdit' -ErrorAction SilentlyContinue;if($m.QuickEdit -eq 1){Set-ItemProperty -Path 'HKCU:\Console' -Name 'QuickEdit' -Value 0 -Force}" >nul 2>&1

:MENU
cls
echo =================================================================
echo        WindowsFixKit - Windows Diagnostic and Auto-Repair
echo      DevSparks India ^| https://devsparksindia.com ^| 9521032268
echo =================================================================
echo.
echo   --- SYSTEM HEALTH ^& DIAGNOSTICS ---
echo   [1]  Full Hardware and System Health Diagnosis (Desktop HTML Report)
echo   [2]  Windows Update and Network Diagnostic + Auto-Fix (diagnose.ps1)
echo   [3]  Genuine Licensing, ESU ^& Security Baseline Audit (check_licensing_health)
echo   [4]  Windows Edition ^& Servicing Readiness Diagnostics (fix_edition_diagnostics)
echo   [5]  BSOD Crash Dump ^& BugCheck Analyzer (fix_bsod_analyzer)
echo.
echo   --- CORE SUBSYSTEM ^& APPLICATION REPAIRS ---
echo   [6]  WMI Repository ^& Core Windows Services Repair (fix_wmi_services)
echo   [7]  Deep DISM Component Store ^& SFC File Repair (fix_sfc_dism_deep)
echo   [8]  Microsoft Office C2R ^& MSI Diagnostic / Repair (fix_office_repair)
echo   [9]  Windows Script Host (WSH) ^& PATH Environment Fixer (fix_wsh_environment)
echo   [10] Fix Windows Update Stuck at 0%% (fix_update_stuck)
echo   [11] Hardware Driver Auto-Repair ^& Catalog Scan (fix_driver_updater)
echo   [12] Windows 10/11 Upgrade Rollback Resolver (fix_upgrade_rollback)
echo   [13] .NET Framework ^& App Install Repair Tool (fix_dotnet_repair)
echo.
echo   --- OPTIMIZATION, NETWORK ^& MAINTENANCE ---
echo   [14] Safe Performance Debloat (fix_performance_debloat)
echo   [15] Telemetry ^& Privacy Registry Hardener (fix_telemetry_privacy)
echo   [16] Deep Junk ^& Temp Files Cleanup (%%TEMP%%, Prefetch, Recycle Bin)
echo   [17] Deep RAM Cache ^& Memory Optimizer (Empty Working Sets)
echo   [18] Full Network and DNS Stack Reset (fix_network_reset)
echo   [19] Fix Missing Wi-Fi Adapter (fix_wifi_missing)
echo   [20] Fix Missing Bluetooth Service (fix_bluetooth_missing)
echo.
echo   --- SUPPORT ^& QUALITY ASSURANCE ---
echo   [21] Package Diagnostic Logs ^& Share with DevSparks India (export_and_share_report)
echo   [22] Run Local CI Lint and Test Check (scripts\lint-check.ps1)
echo   [23] Exit
echo.
echo =================================================================
set /p CHOICE="  Select an option [1-23]: "

if "%CHOICE%"=="1" goto FULL_DIAG
if "%CHOICE%"=="2" goto WU_DIAG
if "%CHOICE%"=="3" goto LIC_DIAG
if "%CHOICE%"=="4" goto EDITION_DIAG
if "%CHOICE%"=="5" goto BSOD_FIX
if "%CHOICE%"=="6" goto WMI_FIX
if "%CHOICE%"=="7" goto SFC_DISM_DEEP
if "%CHOICE%"=="8" goto OFFICE_FIX
if "%CHOICE%"=="9" goto WSH_FIX
if "%CHOICE%"=="10" goto WU_STUCK
if "%CHOICE%"=="11" goto DRIVER_FIX
if "%CHOICE%"=="12" goto UPGRADE_FIX
if "%CHOICE%"=="13" goto DOTNET_FIX
if "%CHOICE%"=="14" goto DEBLOAT
if "%CHOICE%"=="15" goto PRIVACY
if "%CHOICE%"=="16" goto CLEANUP
if "%CHOICE%"=="17" goto RAM_CLEANUP
if "%CHOICE%"=="18" goto NET_RESET
if "%CHOICE%"=="19" goto WIFI_FIX
if "%CHOICE%"=="20" goto BT_FIX
if "%CHOICE%"=="21" goto SHARE_BUNDLE
if "%CHOICE%"=="22" goto LINT_CHECK
if "%CHOICE%"=="23" goto EXIT

echo [!] Invalid selection. Please choose 1 to 23.
timeout /t 2 >nul
goto MENU

:FULL_DIAG
cls
echo [INFO] Running Full Hardware and System Health Audit...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\full_system_diagnosis.ps1"
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:WU_DIAG
cls
echo [INFO] Running Windows Update and Network Diagnostic Engine...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\diagnose.ps1"
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:LIC_DIAG
cls
echo [INFO] Auditing Windows & Office Licensing Health, ESU and Security Baseline...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\diagnostics\check_licensing_health.ps1"
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:EDITION_DIAG
cls
echo [INFO] Diagnosing Windows Edition Upgrade Readiness and Servicing Flags...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fix_edition_diagnostics.ps1"
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:BSOD_FIX
cls
echo [INFO] Analyzing Windows BSOD Crash Dumps & BugChecks...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fix_bsod_analyzer.ps1"
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:WMI_FIX
cls
echo [INFO] Repairing WMI Repository, Null Driver and Core Windows Services...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fix_wmi_services.ps1"
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:SFC_DISM_DEEP
cls
echo [INFO] Running Deep Component Store (DISM) & SFC Repair with Log Bundler...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fix_sfc_dism_deep.ps1"
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:OFFICE_FIX
cls
echo [INFO] Diagnosing Microsoft Office C2R / MSI Suites and Repair Options...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fix_office_repair.ps1"
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:WSH_FIX
cls
echo [INFO] Remediating Windows Script Host (WSH) & System Environment Variables...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fix_wsh_environment.ps1"
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:WU_STUCK
cls
echo [INFO] Remediating Windows Update Stuck at 0%% / Download Hangs...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fix_update_stuck.ps1"
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:DRIVER_FIX
cls
echo [INFO] Scanning & Auto-Repairing Hardware Device Drivers...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fix_driver_updater.ps1"
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:UPGRADE_FIX
cls
echo [INFO] Diagnosing Windows 10/11 Upgrade Rollbacks & Drivers...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fix_upgrade_rollback.ps1"
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:DOTNET_FIX
cls
echo [INFO] Diagnosing .NET Framework & BadImageFormatException...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fix_dotnet_repair.ps1"
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:DEBLOAT
cls
echo [INFO] Running Safe Performance Debloat Module...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fix_performance_debloat.ps1"
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:PRIVACY
cls
echo [INFO] Applying Telemetry & Privacy Registry Hardening...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fix_telemetry_privacy.ps1"
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:CLEANUP
cls
echo [INFO] Running Deep Temp, Trash & Storage Cleanup Engine...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fix_storage_cleanup.ps1"
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:RAM_CLEANUP
cls
echo [INFO] Running Deep RAM Cache & Memory Buffer Optimizer...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fix_ram_cache.ps1"
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:NET_RESET
cls
echo [INFO] Resetting Network Sockets, TCP/IP and DNS...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fix_network_reset.ps1"
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:WIFI_FIX
cls
echo [INFO] Remediating Wi-Fi Adapters and WLAN Services...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fix_wifi_missing.ps1"
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:BT_FIX
cls
echo [INFO] Remediating Bluetooth Support Services and Radios...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fix_bluetooth_missing.ps1"
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:SHARE_BUNDLE
cls
echo [INFO] Packaging Diagnostic Logs & Preparing Support Bundle...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\export_and_share_report.ps1"
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:LINT_CHECK
cls
echo [INFO] Running Quality Gate and Lint Suite...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\lint-check.ps1"
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:EXIT
exit /b 0
