@echo off
:: ============================================================================
::  WindowsFixKit - Master One-Click Launcher
::  Target: Windows 7, 8.1, 10, 11
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
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath \"$env:ComSpec\" -ArgumentList '/k \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

:: Ensure working directory is the script directory
cd /d "%~dp0"

:MENU
cls
echo =================================================================
echo        WindowsFixKit - Windows Diagnostic and Auto-Repair
echo       Owner: nkdhawan76 ^| Supported: Windows 7, 8.1, 10, 11
echo =================================================================
echo.
echo   [1] Full Hardware and System Health Diagnosis (Desktop HTML Report)
echo   [2] Windows Update and Network Diagnostic + Auto-Fix (diagnose.ps1)
echo   [3] Scan-Only Mode (Detect issues without making changes)
echo   [4] Quick Disk Space Cleanup and Cache Recovery (fix_storage_cleanup)
echo   [5] Full Network and DNS Stack Reset (fix_network_reset)
echo   [6] Fix Missing Wi-Fi Adapter (fix_wifi_missing)
echo   [7] Fix Missing Bluetooth Service (fix_bluetooth_missing)
echo   [8] Run Local CI Lint and Test Check (scripts\lint-check.ps1)
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
echo [>>>] Running Full Hardware and System Health Audit...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\full_system_diagnosis.ps1"
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:WU_DIAG
cls
echo [>>>] Running Windows Update and Network Diagnostic Engine...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\diagnose.ps1"
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:SCAN_ONLY
cls
echo [>>>] Running Scan-Only Diagnostic...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\diagnose.ps1" -ScanOnly
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:CLEANUP
cls
echo [>>>] Running Storage Cleanup and Cache Recovery...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fix_storage_cleanup.ps1"
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:NET_RESET
cls
echo [>>>] Resetting Network Sockets, TCP/IP and DNS...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fix_network_reset.ps1"
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:WIFI_FIX
cls
echo [>>>] Remediating Wi-Fi Adapters and WLAN Services...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fix_wifi_missing.ps1"
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:BT_FIX
cls
echo [>>>] Remediating Bluetooth Support Services and Radios...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fix_bluetooth_missing.ps1"
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:LINT_CHECK
cls
echo [>>>] Running Quality Gate and Lint Suite...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\lint-check.ps1"
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:EXIT
exit /b 0
