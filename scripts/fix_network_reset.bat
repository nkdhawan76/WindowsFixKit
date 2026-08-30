@echo off
:: ============================================================================
:: WindowsFixKit - Full Network Reset (CMD/Batch Fallback)
:: Target: Windows 7, 8.1, 10, 11
:: ============================================================================

echo =========================================================
echo  [WindowsFixKit] Full Network Reset (CMD Fallback)
echo =========================================================

:: Check for Administrative Privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] Error: Administrative privileges required.
    echo Please right-click this script and select 'Run as administrator'.
    exit /b 1
)

echo.
echo [+] Step 1: Resetting Winsock Catalog...
netsh winsock reset >nul 2>&1
echo [OK] Winsock catalog reset.

echo.
echo [+] Step 2: Resetting TCP/IP Stack...
netsh int ip reset >nul 2>&1
netsh int ipv6 reset >nul 2>&1
echo [OK] TCP/IP and IPv6 stack reset.

echo.
echo [+] Step 3: Purging ARP Cache...
netsh interface ip delete arpcache >nul 2>&1
echo [OK] ARP cache purged.

echo.
echo [+] Step 4: Releasing and Renewing IP Address...
ipconfig /release >nul 2>&1
ipconfig /renew >nul 2>&1
echo [OK] DHCP address renewed.

echo.
echo [+] Step 5: Flushing and Registering DNS...
ipconfig /flushdns >nul 2>&1
ipconfig /registerdns >nul 2>&1
echo [OK] DNS resolver refreshed.

echo.
echo =========================================================
echo  [STATUS] Network Reset Completed. A reboot is recommended.
echo =========================================================
exit /b 0
