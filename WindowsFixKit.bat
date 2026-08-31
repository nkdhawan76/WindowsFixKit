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

:MENU
cls
echo =================================================================
echo        WindowsFixKit - Windows Diagnostic and Auto-Repair
echo      DevSparks India ^| https://devsparksindia.com ^| 9521032268
echo =================================================================
echo.
echo   [1]  Full Hardware and System Health Diagnosis (Desktop HTML Report)
echo   [2]  Windows Update and Network Diagnostic + Auto-Fix (diagnose.ps1)
echo   [3]  Fix Windows Update Stuck at 0%% (fix_update_stuck)
echo   [4]  BSOD Crash Dump & BugCheck Analyzer (fix_bsod_analyzer)
echo   [5]  Hardware Driver Auto-Repair & Catalog Scan (fix_driver_updater)
echo   [6]  Windows 10/11 Upgrade Rollback Resolver (fix_upgrade_rollback)
echo   [7]  Safe Performance Debloat (fix_performance_debloat)
echo   [8]  Telemetry & Privacy Registry Hardener (fix_telemetry_privacy)
echo   [9]  .NET Framework & App Install Repair Tool (fix_dotnet_repair)
echo   [10] Deep Junk & Temp Files Cleanup (%%TEMP%%, Prefetch, Recycle Bin)
echo   [11] Deep RAM Cache & Memory Optimizer (Empty Working Sets)
echo   [12] Full Network and DNS Stack Reset (fix_network_reset)
echo   [13] Fix Missing Wi-Fi Adapter (fix_wifi_missing)
echo   [14] Fix Missing Bluetooth Service (fix_bluetooth_missing)
echo   [15] Package Diagnostic Logs & Share with DevSparks India (export_and_share_report)
echo   [16] Run Local CI Lint and Test Check (scripts\lint-check.ps1)
echo   [17] Exit
echo.
echo =================================================================
set /p CHOICE="  Select an option [1-17]: "

if "%CHOICE%"=="1" goto FULL_DIAG
if "%CHOICE%"=="2" goto WU_DIAG
if "%CHOICE%"=="3" goto WU_STUCK
if "%CHOICE%"=="4" goto BSOD_FIX
if "%CHOICE%"=="5" goto DRIVER_FIX
if "%CHOICE%"=="6" goto UPGRADE_FIX
if "%CHOICE%"=="7" goto DEBLOAT
if "%CHOICE%"=="8" goto PRIVACY
if "%CHOICE%"=="9" goto DOTNET_FIX
if "%CHOICE%"=="10" goto CLEANUP
if "%CHOICE%"=="11" goto RAM_CLEANUP
if "%CHOICE%"=="12" goto NET_RESET
if "%CHOICE%"=="13" goto WIFI_FIX
if "%CHOICE%"=="14" goto BT_FIX
if "%CHOICE%"=="15" goto SHARE_BUNDLE
if "%CHOICE%"=="16" goto LINT_CHECK
if "%CHOICE%"=="17" goto EXIT

echo [!] Invalid selection. Please choose 1 to 17.
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

:WU_STUCK
cls
echo [INFO] Remediating Windows Update Stuck at 0%% / Download Hangs...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fix_update_stuck.ps1"
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

:DOTNET_FIX
cls
echo [INFO] Diagnosing .NET Framework & BadImageFormatException...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fix_dotnet_repair.ps1"
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
