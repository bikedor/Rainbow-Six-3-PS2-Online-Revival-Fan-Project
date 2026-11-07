@echo off
title RS3 PS2 Server - add firewall rules
rem ---------------------------------------------------------------------------
rem  Opens inbound TCP/UDP for every port the RS3 server stack binds to, so
rem  PCSX2 / the real console can actually reach it. Safe to re-run; existing
rem  rules with the same name are replaced, not duplicated.
rem
rem  Symptom this fixes: every service log under logs\ shows only its startup
rem  banner (DNS, router 40000, HTTP 80, etc.) with zero inbound packets ever
rem  logged, even though the ports are confirmed bound and the host IP
rem  (192.168.1.113) is correct -- i.e. Windows Firewall is silently dropping
rem  inbound traffic before it reaches the python/listener sockets.
rem
rem  Run add_rs3_firewall_rules.bat once, then relaunch "RS3 Server.bat".
rem  Run remove_rs3_firewall_rules.bat later to undo.
rem ---------------------------------------------------------------------------

net session >nul 2>&1
if errorlevel 1 (
  echo Requesting administrator rights...
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

set "RULE_PREFIX=RS3 PS2 Server"

echo ==================================================
echo   Adding Windows Firewall rules: %RULE_PREFIX%
echo ==================================================
echo.

rem --- TCP ports --------------------------------------------------------------
rem 40000 = router, 40005 = wait module / lobby, 44001 = persistent proxy,
rem 44002 = ladder/ranking proxy, 80 = gsinit (GS HTTP), 443 = DNAS,
rem 44000/45000/6667/6668 = chat + misc (tcp_ports.log catch-all),
rem 27900/27901/28910/29900/29901/29920 = GameSpy query/echo ports,
rem 7777 = Unreal Engine 2 in-match traffic
set "TCP_PORTS=40000,40005,44000,44001,44002,45000,6667,6668,80,443,27900,27901,28910,29900,29901,29920,7777"

rem --- UDP ports ----------------------------------------------------------------
rem 53 = DNS override/forwarder, 45000 = GSNAT (NAT traversal),
rem 19341 = UDP logger, 3658 = in-match NAT ENABLE traffic,
rem 4400/41006/10070-10080 = manual/legacy ports,
rem 27900/27901/28910/29900/29901/29920 = GameSpy query/echo ports
set "UDP_PORTS=53,45000,19341,3658,4400,41006,10070,10071,10072,10073,10074,10075,10076,10077,10078,10079,10080,27900,27901,28910,29900,29901,29920"

echo [1/4] Removing any existing "%RULE_PREFIX%" rules (clean re-add)...
netsh advfirewall firewall delete rule name="%RULE_PREFIX% TCP In"  >nul 2>&1
netsh advfirewall firewall delete rule name="%RULE_PREFIX% TCP Out" >nul 2>&1
netsh advfirewall firewall delete rule name="%RULE_PREFIX% UDP In"  >nul 2>&1
netsh advfirewall firewall delete rule name="%RULE_PREFIX% UDP Out" >nul 2>&1
netsh advfirewall firewall delete rule name="%RULE_PREFIX% dnasrep.exe" >nul 2>&1

echo [2/4] Adding inbound/outbound TCP rules for: %TCP_PORTS%
netsh advfirewall firewall add rule name="%RULE_PREFIX% TCP In"  dir=in  action=allow protocol=TCP localport=%TCP_PORTS% profile=any
netsh advfirewall firewall add rule name="%RULE_PREFIX% TCP Out" dir=out action=allow protocol=TCP localport=%TCP_PORTS% profile=any

echo [3/4] Adding inbound/outbound UDP rules for: %UDP_PORTS%
netsh advfirewall firewall add rule name="%RULE_PREFIX% UDP In"  dir=in  action=allow protocol=UDP localport=%UDP_PORTS% profile=any
netsh advfirewall firewall add rule name="%RULE_PREFIX% UDP Out" dir=out action=allow protocol=UDP localport=%UDP_PORTS% profile=any

echo [4/4] Allowing dnasrep.exe by program path (TLS 443 handler)...
if exist "%~dp0dnasrep_test\dnasrep.exe" (
  netsh advfirewall firewall add rule name="%RULE_PREFIX% dnasrep.exe" dir=in action=allow program="%~dp0dnasrep_test\dnasrep.exe" enable=yes profile=any
) else (
  echo   (skipped: dnasrep_test\dnasrep.exe not found next to this script)
)

echo.
echo Done. Current "%RULE_PREFIX%" rules:
netsh advfirewall firewall show rule name=all | findstr /C:"%RULE_PREFIX%"
echo.
echo Now relaunch "RS3 Server.bat" and try connecting again.
pause
