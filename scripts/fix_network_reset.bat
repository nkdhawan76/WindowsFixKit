@echo off
:: ============================================================================
:: WindowsFixKit - Network Reset Script (CMD/Batch Fallback)
:: Target: Windows 7, 8.1, 10, 11
:: ============================================================================

title WindowsFixKit - Network Reset
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
echo  [WindowsFixKit] Resetting Network Stack
echo =========================================================

echo.
echo [+] Step 1: Resetting Winsock Catalog...
netsh winsock reset >nul 2>&1
echo [OK] Winsock catalog reset.

echo.
echo [+] Step 2: Resetting TCP/IP Stack...
netsh int ip reset >nul 2>&1
echo [OK] TCP/IP stack reset.

echo.
echo [+] Step 3: Flushing and Re-registering DNS...
ipconfig /flushdns >nul 2>&1
ipconfig /registerdns >nul 2>&1
echo [OK] DNS resolver flushed and re-registered.

echo.
echo [+] Step 4: Releasing and Renewing DHCP Leases...
ipconfig /release >nul 2>&1
ipconfig /renew >nul 2>&1
echo [OK] DHCP leases refreshed.

echo.
echo =========================================================
echo  [STATUS] Network Reset Completed. A system restart is recommended.
echo =========================================================
echo.
echo Press any key to exit...
pause >nul
exit /b 0
