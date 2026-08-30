@echo off
:: ============================================================================
:: WindowsFixKit - DNS Reset & Configuration Script (CMD/Batch Fallback)
:: Target: Windows 7, 8.1, 10, 11
:: ============================================================================

title WindowsFixKit - DNS Fix
color 0A

:: Ensure working directory is the script directory
cd /d "%~dp0"

:: Check for Administrator Privileges and Self-Elevate
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo =========================================================
    echo  [!] Requesting Administrator privileges...
    echo =========================================================
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo =========================================================
echo  [WindowsFixKit] Fixing DNS Resolution (CMD Fallback)
echo =========================================================

echo.
echo [+] Step 1: Flushing DNS Cache...
ipconfig /flushdns >nul 2>&1
echo [OK] DNS Cache flushed.

echo.
echo [+] Step 2: Restarting DNS Client Service (Dnscache)...
net stop dnscache >nul 2>&1
net start dnscache >nul 2>&1
echo [OK] DNS Cache service refreshed.

echo.
echo [+] Step 3: Re-registering DNS with Domain Controller / Gateway...
ipconfig /registerdns >nul 2>&1
echo [OK] DNS registration initiated.

echo.
echo [+] Step 4: Configuring Public DNS Fallbacks (Cloudflare 1.1.1.1 & Google 8.8.8.8)...
for /f "tokens=4*" %%a in ('netsh interface show interface ^| findstr /i "Connected"') do (
    echo   [-] Configuring DNS on interface: %%b
    netsh interface ip set dns name="%%b" static 1.1.1.1 primary >nul 2>&1
    netsh interface ip add dns name="%%b" 8.8.8.8 index=2 >nul 2>&1
)
echo [OK] Public DNS fallbacks applied.

echo.
echo =========================================================
echo  [STATUS] DNS Remediation Completed.
echo =========================================================
echo.
pause
exit /b 0
