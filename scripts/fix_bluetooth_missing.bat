@echo off
:: ============================================================================
:: WindowsFixKit - Bluetooth Missing Fix Script (CMD/Batch Fallback)
:: Target: Windows 7, 8.1, 10, 11
:: ============================================================================

title WindowsFixKit - Bluetooth Fix
color 0A

:: Check for Administrator Privileges and Self-Elevate
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo =========================================================
    echo  [!] Requesting Administrator privileges...
    echo =========================================================
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath \"$env:ComSpec\" -ArgumentList '/k \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

:: Ensure working directory is the script directory
cd /d "%~dp0"

echo =========================================================
echo  [WindowsFixKit] Fixing Bluetooth Service
echo =========================================================

echo.
echo [+] Step 1: Configuring and Starting Bluetooth Support Services...
sc config bthserv start= auto >nul 2>&1
net start bthserv >nul 2>&1

sc config bthHFSrv start= auto >nul 2>&1
net start bthHFSrv >nul 2>&1

sc config BTAGService start= auto >nul 2>&1
net start BTAGService >nul 2>&1
echo [OK] Bluetooth services configured.

echo.
echo [+] Step 2: Rescanning Device Tree for Bluetooth Radios...
pnputil /scan-devices >nul 2>&1
echo [OK] Device tree rescan completed.

echo.
echo =========================================================
echo  [STATUS] Bluetooth Fix Script Execution Completed.
echo =========================================================
echo.
echo Press any key to exit...
pause >nul
exit /b 0
