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
echo   [3]  Scan-Only Mode (Detect issues without making changes)
echo   [4]  Deep Junk & Temp Files Cleanup (%%TEMP%%, Prefetch, Recycle Bin, Cleanmgr)
echo   [5]  Deep RAM Cache & Memory Optimizer (Empty Working Sets, Trim Cache)
echo   [6]  Full Network and DNS Stack Reset (fix_network_reset)
echo   [7]  Fix Missing Wi-Fi Adapter (fix_wifi_missing)
echo   [8]  Fix Missing Bluetooth Service (fix_bluetooth_missing)
echo   [9]  Run Local CI Lint and Test Check (scripts\lint-check.ps1)
echo   [10] Exit
echo.
echo =================================================================
set /p CHOICE="  Select an option [1-10]: "

if "%CHOICE%"=="1" goto FULL_DIAG
if "%CHOICE%"=="2" goto WU_DIAG
if "%CHOICE%"=="3" goto SCAN_ONLY
if "%CHOICE%"=="4" goto CLEANUP
if "%CHOICE%"=="5" goto RAM_CLEANUP
if "%CHOICE%"=="6" goto NET_RESET
if "%CHOICE%"=="7" goto WIFI_FIX
if "%CHOICE%"=="8" goto BT_FIX
if "%CHOICE%"=="9" goto LINT_CHECK
if "%CHOICE%"=="10" goto EXIT

echo [!] Invalid selection. Please choose 1 to 10.
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

:SCAN_ONLY
cls
echo [INFO] Running Scan-Only Diagnostic...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\diagnose.ps1" -ScanOnly
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
