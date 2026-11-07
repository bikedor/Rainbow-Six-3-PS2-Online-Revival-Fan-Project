@echo off
rem RS3 packet sniffer for a real PS2. RUN AS ADMINISTRATOR. Logs to logs\ps2_sniff_<ip>.log
rem Sees every packet between the PS2 and this PC (192.168.1.113). Needs no extra packages.
rem Sniffs the main PS2 (192.168.1.218). Another address can be given: run_sniff_ps2.bat 192.168.1.x
cd /d "%~dp0"
net session >nul 2>&1
if errorlevel 1 (
  echo Requesting administrator rights...
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -ArgumentList '%*' -Verb RunAs"
  exit /b
)
set "PS2IP=%~1"
if "%PS2IP%"=="" set "PS2IP=192.168.1.218"
if not exist "logs\" mkdir "logs"
if exist ".venv\Scripts\python.exe" (set "PY=.venv\Scripts\python.exe") else (set "PY=python")
echo Sniffing %PS2IP%, log: logs\ps2_sniff_%PS2IP%.log   (Ctrl+C to stop)
"%PY%" tools\sniff_ps2.py --ps2 %PS2IP% --bind 192.168.1.113 --log "logs\ps2_sniff_%PS2IP%.log" --skip-tcp-data
pause
