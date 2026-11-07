@echo off
title RS3 PS2 Server - remove firewall rules
rem Undoes add_rs3_firewall_rules.bat: deletes the "RS3 PS2 Server" rule set.

net session >nul 2>&1
if errorlevel 1 (
  echo Requesting administrator rights...
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

set "RULE_PREFIX=RS3 PS2 Server"

echo Removing "%RULE_PREFIX%" firewall rules...
netsh advfirewall firewall delete rule name="%RULE_PREFIX% TCP In"
netsh advfirewall firewall delete rule name="%RULE_PREFIX% TCP Out"
netsh advfirewall firewall delete rule name="%RULE_PREFIX% UDP In"
netsh advfirewall firewall delete rule name="%RULE_PREFIX% UDP Out"
netsh advfirewall firewall delete rule name="%RULE_PREFIX% dnasrep.exe"

echo Done.
pause
