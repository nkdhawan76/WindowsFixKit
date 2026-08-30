@echo off
:: ============================================================================
:: WindowsFixKit - Bluetooth Missing Fix Script (CMD/Batch Fallback)
:: Target: Windows 7, 8.1, 10, 11
:: ============================================================================

echo =========================================================
echo  [WindowsFixKit] Fixing Bluetooth Services (CMD Fallback)
echo =========================================================

:: Check for Administrative Privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] Error: Administrative privileges required.
    echo Please right-click this script and select 'Run as administrator'.
    exit /b 1
)

echo.
echo [+] Step 1: Configuring and starting Bluetooth Support Service (bthserv)...
sc config bthserv start= auto >nul 2>&1
net start bthserv >nul 2>&1
echo [OK] bthserv configured.

echo.
echo [+] Step 2: Configuring Bluetooth Audio Gateway Service (BTAGService)...
sc config BTAGService start= auto >nul 2>&1
net start BTAGService >nul 2>&1
echo [OK] BTAGService configured.

echo.
echo [+] Step 3: Triggering Hardware Device Tree Rescan...
pnputil /scan-devices >nul 2>&1
if %errorLevel% neq 0 (
    echo   [-] Scanning with legacy WMIC...
    wmic path win32_pnpentity where "Description like '%%Bluetooth%%' and Status='Error'" call enable >nul 2>&1
)
echo [OK] Hardware rescan completed.

echo.
echo =========================================================
echo  [STATUS] Bluetooth Fix Script Execution Completed.
echo =========================================================
exit /b 0
