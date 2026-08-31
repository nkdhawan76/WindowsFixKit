@echo off
:: ============================================================================
::  WindowsFixKit - WMI Repository and Core Services Repair Launcher
::  Target: Windows 7, 8.1, 10, 11
::  DevSparks India | https://devsparksindia.com | 9521032268
:: ============================================================================

title WindowsFixKit - WMI and Core Services Repair
color 0B

:: Check for Administrator Privileges
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

echo =================================================================
echo   WindowsFixKit - WMI and Core Services Auto-Repair
echo   DevSparks India ^| https://devsparksindia.com ^| 9521032268
echo =================================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0fix_wmi_services.ps1"

echo.
echo =================================================================
echo   Repair operation complete.
echo =================================================================
pause
