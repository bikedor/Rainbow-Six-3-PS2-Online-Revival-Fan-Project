@echo off
title RS3 Server launcher (Rainbow Six 3 PS2, SLUS-20883)
cd /d "%~dp0"
rem ---------------------------------------------------------------------------
rem  Rainbow Six 3 PS2 (SLUS-20883) Ubi.com GS server launcher.
rem  Detects this PC's LAN IP automatically, opens the firewall ports the
rem  stack needs, then starts the server. No manual IP editing required for
rem  LAN / PCSX2 play -- see the INTERNET PLAY block below if you also want
rem  to let players connect over the internet (off by default).
rem ---------------------------------------------------------------------------
net session >nul 2>&1
if errorlevel 1 (
  echo Requesting administrator rights...
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

rem --- RS3 settings (inherited by every server window started below) ---------
set "SCCT_GSINIT_FILE=gsinit_rs3.php"
set "SCCT_FRIEND_GAME=RAINBOWSIX3PS2US"
set "RS3_STACK=rs3\run_rs3_stack.bat"
rem ct34 = Chaos Theory-only extra frames after login. off = plain replies (RS3 test 2)
set "RS3_CT34=off"

rem --- INTERNET PLAY (off by default -- LAN/PCSX2 only) -----------------------
rem To let players connect over the internet instead of just your LAN:
rem   1. Set SCCT_ALLOW_PUBLIC=1 below.
rem   2. Either set SCCT_PUBLIC_IP to your router's public IP yourself, or
rem      leave it blank to have this script look it up for you automatically.
rem   3. Forward the ports listed in add_rs3_firewall_rules.bat on your router.
rem This is a LAN party-style server with no real auth -- only do this with
rem people you trust.
set "SCCT_ALLOW_PUBLIC=0"
set "SCCT_PUBLIC_IP="
if "%SCCT_ALLOW_PUBLIC%"=="1" if "%SCCT_PUBLIC_IP%"=="" (
  echo Looking up your public IP for internet play...
  for /f "usebackq delims=" %%I in (`powershell -NoProfile -Command "try { (Invoke-RestMethod -Uri 'https://api.ipify.org' -TimeoutSec 5) } catch { '' }"`) do set "SCCT_PUBLIC_IP=%%I"
  if "%SCCT_PUBLIC_IP%"=="" (
    echo WARNING: could not auto-detect your public IP. Internet players will not
    echo   be able to connect until you set SCCT_PUBLIC_IP manually in this file.
  ) else (
    echo Public IP detected: %SCCT_PUBLIC_IP%
  )
)

echo ==================================================
echo   RS3 Server  -  Rainbow Six 3 PS2 server launcher
echo ==================================================
echo.

rem --- Detect this PC's LAN IP automatically -----------------------------------
echo Detecting this PC's LAN IP address...
set "RS3_HOST_IP="
for /f "usebackq delims=" %%I in (`powershell -NoProfile -Command ^
  "(Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -and $_.NetAdapter.Status -eq 'Up' } | Select-Object -First 1 -ExpandProperty IPv4Address).IPAddress"`) do set "RS3_HOST_IP=%%I"
if "%RS3_HOST_IP%"=="" (
  echo WARNING: could not auto-detect a LAN IP. Falling back to 192.168.1.113 --
  echo   edit RS3_HOST_IP in this file if that is wrong for your network.
  set "RS3_HOST_IP=192.168.1.113"
)
echo Detected LAN IP: %RS3_HOST_IP%
echo.

if not exist "%RS3_STACK%" (
  echo ERROR: %RS3_STACK% not found in %CD%
  pause
  exit /b 1
)
if not exist "gsinit_rs3.php" (
  echo ERROR: gsinit_rs3.php not found in %CD%
  pause
  exit /b 1
)
if not exist "dnasrep_test\dnasrep.exe" (
  echo ERROR: dnasrep_test\dnasrep.exe not found.
  echo   See README.md for where to get it -- it is not included in this repo.
  pause
  exit /b 1
)

rem --- Open the firewall ports this stack needs (silent, no extra prompt) -----
echo Opening firewall ports for the RS3 server stack...
set "RS3_FW_PREFIX=RS3 PS2 Server"
set "RS3_FW_TCP=40000,40005,44000,44001,44002,45000,6667,6668,80,443,27900,27901,28910,29900,29901,29920,7777"
set "RS3_FW_UDP=53,45000,19341,3658,4400,41006,10070,10071,10072,10073,10074,10075,10076,10077,10078,10079,10080,27900,27901,28910,29900,29901,29920"
netsh advfirewall firewall delete rule name="%RS3_FW_PREFIX% TCP In"  >nul 2>&1
netsh advfirewall firewall delete rule name="%RS3_FW_PREFIX% TCP Out" >nul 2>&1
netsh advfirewall firewall delete rule name="%RS3_FW_PREFIX% UDP In"  >nul 2>&1
netsh advfirewall firewall delete rule name="%RS3_FW_PREFIX% UDP Out" >nul 2>&1
netsh advfirewall firewall delete rule name="%RS3_FW_PREFIX% dnasrep.exe" >nul 2>&1
netsh advfirewall firewall add rule name="%RS3_FW_PREFIX% TCP In"  dir=in  action=allow protocol=TCP localport=%RS3_FW_TCP% profile=any >nul
netsh advfirewall firewall add rule name="%RS3_FW_PREFIX% TCP Out" dir=out action=allow protocol=TCP localport=%RS3_FW_TCP% profile=any >nul
netsh advfirewall firewall add rule name="%RS3_FW_PREFIX% UDP In"  dir=in  action=allow protocol=UDP localport=%RS3_FW_UDP% profile=any >nul
netsh advfirewall firewall add rule name="%RS3_FW_PREFIX% UDP Out" dir=out action=allow protocol=UDP localport=%RS3_FW_UDP% profile=any >nul
if exist "%~dp0dnasrep_test\dnasrep.exe" (
  netsh advfirewall firewall add rule name="%RS3_FW_PREFIX% dnasrep.exe" dir=in action=allow program="%~dp0dnasrep_test\dnasrep.exe" enable=yes profile=any >nul
)
echo Firewall rules in place (run remove_rs3_firewall_rules.bat later to undo).
echo.

rem --- Move the old logs aside so this run's logs contain RS3 traffic only. ---
if not exist "logs\" goto logs_ready
for /f %%T in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "RS3_TS=%%T"
if not exist "_archive\" mkdir "_archive"
move "logs" "_archive\logs_before_rs3_%RS3_TS%" >nul
echo Previous logs moved to _archive\logs_before_rs3_%RS3_TS%
:logs_ready
mkdir "logs" >nul 2>&1

echo Starting the cleanup watcher (closing this window stops the whole server).
if exist "%~dp0scops_stop.ps1" start "" /min powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0scops_stop.ps1" -WatchParent
echo [1/3] Starting the server stack...
start "SCOPS stack (RS3)" cmd /c call "%RS3_STACK%"
echo [2/3] Waiting for port 40005 (up to 60 s)...
powershell -NoProfile -Command "$t=0; while($t -lt 60){ if(Get-NetTCPConnection -State Listen -LocalPort 40005 -ErrorAction SilentlyContinue){exit 0}; Start-Sleep -Seconds 1; $t++}; exit 1"
if errorlevel 1 (
  echo WARNING: port 40005 did not come up. Check the SCOPS stack RS3 window and logs\router_wm_40005.log
) else (
  echo Lobby server is up.
)
timeout /t 3 /nobreak >nul
echo [3/3] Starting DNAS on port 443...
start "SCOPS DNAS (RS3)" /d "%~dp0dnasrep_test" cmd /c run_dnasrep_443_only.bat
echo.
echo ==================================================
echo   Server is running. Now on the console/PCSX2:
echo     1. Boot Rainbow Six 3 (DNS = %RS3_HOST_IP%)
echo     2. Go to Online / Ubi.com and try to sign in
echo     3. Note the exact message on screen and where it stops
echo   Then come back here and press any key to stop.
echo   Afterwards run rs3\collect_rs3_logs.bat
echo ==================================================
echo.
pause >nul
echo Stopping...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scops_stop.ps1"
timeout /t 3 >nul
