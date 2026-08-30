@echo off
:: ============================================================================
:: WindowsFixKit - DNS Fix Script (CMD/Batch Fallback)
:: Target: Windows 7, 8.1, 10, 11
:: ============================================================================

echo =========================================================
echo  [WindowsFixKit] Fixing DNS Resolution (CMD Fallback)
echo =========================================================

:: Check for Administrative Privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] Error: Administrative privileges required.
    echo Please right-click this script and select 'Run as administrator'.
    exit /b 1
)

echo.
echo [+] Step 1: Flushing DNS Cache and NetBIOS Name Table...
ipconfig /flushdns >nul 2>&1
nbtstat -R >nul 2>&1
ipconfig /registerdns >nul 2>&1
echo [OK] DNS cache cleared.

echo.
echo [+] Step 2: Setting Public DNS (1.1.1.1 / 8.8.8.8) on Connected Adapters...
for /f "tokens=4*" %%a in ('netsh interface show interface ^| findstr /i "Connected"') do (
    echo   [-] Setting DNS on interface: %%b
    netsh interface ip set dns name="%%b" static 1.1.1.1 primary >nul 2>&1
    netsh interface ip add dns name="%%b" 8.8.8.8 index=2 >nul 2>&1
)
echo [OK] Public DNS configured.

echo.
echo [+] Step 3: Verifying Resolution with Nslookup...
nslookup google.com 1.1.1.1 >nul 2>&1
if %errorLevel% equ 0 (
    echo [OK] DNS resolution verified successfully.
) else (
    echo [!] Warning: Could not resolve google.com. Check physical network link.
)

echo.
echo =========================================================
echo  [STATUS] DNS Remediation Script Completed.
echo =========================================================
exit /b 0
