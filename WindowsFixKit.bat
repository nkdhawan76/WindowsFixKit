@echo off
:: ============================================================================
::  WindowsFixKit - Master One-Click Launcher
::  Automated Administrator Elevation & Interactive Diagnostic Menu
:: ============================================================================

title WindowsFixKit - System Diagnostic & Auto-Fix Toolkit
color 0B

:: Ensure working directory is the script directory
cd /d "%~dp0"

:: Check for Administrator Privileges and Self-Elevate
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo =================================================================
    echo   [!] Administrative Privileges Required
    echo   Requesting User Account Control (UAC) elevation...
    echo =================================================================
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:MENU
cls
echo =================================================================
echo        WindowsFixKit - Windows Diagnostic & Auto-Repair Toolkit
echo       Owner: nkdhawan76 ^| Supported: Windows 7, 8.1, 10, 11
echo =================================================================
echo.
echo   [1] Full Hardware & System Health Diagnosis (HTML Report)
echo   [2] Windows Update & Network Diagnostic + Auto-Fix (diagnose.ps1)
echo   [3] Scan-Only Mode (Detect issues without making changes)
echo   [4] Quick Disk Space Cleanup & Cache Recovery (fix_storage_cleanup)
echo   [5] Full Network & DNS Stack Reset (fix_network_reset)
echo   [6] Fix Missing Wi-Fi Adapter (fix_wifi_missing)
echo   [7] Fix Missing Bluetooth Service (fix_bluetooth_missing)
echo   [8] Run Local CI Lint & Test Check (scripts\lint-check.ps1)
echo   [9] Exit
echo.
echo =================================================================
set /p CHOICE="  Select an option [1-9]: "

if "%CHOICE%"=="1" goto FULL_DIAG
if "%CHOICE%"=="2" goto WU_DIAG
if "%CHOICE%"=="3" goto SCAN_ONLY
if "%CHOICE%"=="4" goto CLEANUP
if "%CHOICE%"=="5" goto NET_RESET
if "%CHOICE%"=="6" goto WIFI_FIX
if "%CHOICE%"=="7" goto BT_FIX
if "%CHOICE%"=="8" goto LINT_CHECK
if "%CHOICE%"=="9" goto EXIT

echo [!] Invalid selection. Please choose 1 to 9.
timeout /t 2 >nul
goto MENU

:FULL_DIAG
cls
echo [>>>] Running Full Hardware & System Health Audit...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\full_system_diagnosis.ps1"
echo.
pause
goto MENU

:WU_DIAG
cls
echo [>>>] Running Windows Update & Network Diagnostic Engine...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\diagnose.ps1"
echo.
pause
goto MENU

:SCAN_ONLY
cls
echo [>>>] Running Scan-Only Diagnostic...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\diagnose.ps1" -ScanOnly
echo.
pause
goto MENU

:CLEANUP
cls
echo [>>>] Running Storage Cleanup & Cache Recovery...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fix_storage_cleanup.ps1"
echo.
pause
goto MENU

:NET_RESET
cls
echo [>>>] Resetting Network Sockets, TCP/IP & DNS...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fix_network_reset.ps1"
echo.
pause
goto MENU

:WIFI_FIX
cls
echo [>>>] Remediating Wi-Fi Adapters & WLAN Services...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fix_wifi_missing.ps1"
echo.
pause
goto MENU

:BT_FIX
cls
echo [>>>] Remediating Bluetooth Support Services & Radios...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fix_bluetooth_missing.ps1"
echo.
pause
goto MENU

:LINT_CHECK
cls
echo [>>>] Running Quality Gate & Lint Suite...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\lint-check.ps1"
echo.
pause
goto MENU

:EXIT
exit /b 0
