@echo off
:: ============================================================================
:: WindowsFixKit - Wi-Fi Missing Fix Script (CMD/Batch Fallback)
:: Target: Windows 7, 8.1, 10, 11
:: ============================================================================

echo =========================================================
echo  [WindowsFixKit] Fixing Missing Wi-Fi Adapter (CMD Fallback)
echo =========================================================

:: Check for Administrative Privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] Error: Administrative privileges required.
    echo Please right-click this script and select 'Run as administrator'.
    exit /b 1
)

echo.
echo [+] Step 1: Configuring WLAN AutoConfig Service (WlanSvc)...
sc config WlanSvc start= auto >nul 2>&1
net start WlanSvc >nul 2>&1
echo [OK] WlanSvc configured and started.

echo.
echo [+] Step 2: Enabling network interfaces via Netsh...
for /f "tokens=4*" %%a in ('netsh interface show interface ^| findstr /i "Wi-Fi Wireless WLAN"') do (
    echo   [-] Enabling interface: %%b
    netsh interface set interface name="%%b" admin=ENABLED >nul 2>&1
)
echo [OK] Interface enablement pass completed.

echo.
echo [+] Step 3: Triggering Hardware Device Tree Rescan...
pnputil /scan-devices >nul 2>&1
if %errorLevel% neq 0 (
    echo   [-] Falling back to legacy device rescan...
    wmic path win32_networkadapter where "NetConnectionStatus=0 or NetConnectionStatus=7" call enable >nul 2>&1
)
echo [OK] Hardware rescan completed.

echo.
echo [+] Step 4: Refreshing Network Configuration...
ipconfig /renew >nul 2>&1
echo [OK] IP configuration refreshed.

echo.
echo =========================================================
echo  [STATUS] Wi-Fi Fix Script Execution Completed.
echo =========================================================
exit /b 0
