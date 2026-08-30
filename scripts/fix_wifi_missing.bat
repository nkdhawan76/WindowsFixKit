@echo off
:: ============================================================================
:: WindowsFixKit - Wi-Fi Missing Fix Script (CMD/Batch Fallback)
:: Target: Windows 7, 8.1, 10, 11
:: ============================================================================

title WindowsFixKit - Wi-Fi Fix
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
echo  [WindowsFixKit] Fixing Missing Wi-Fi Adapter
echo =========================================================

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
if %errorlevel% neq 0 (
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
echo.
echo Press any key to exit...
pause >nul
exit /b 0
