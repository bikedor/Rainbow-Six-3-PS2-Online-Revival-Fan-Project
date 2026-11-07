@echo off
rem Zips this run's logs and DNAS log into rs3\runs\rs3_run_<time>.zip
cd /d "%~dp0.."
for /f %%T in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "TS=%%T"
if not exist "rs3\runs\" mkdir "rs3\runs"
set "OUT=rs3\runs\rs3_run_%TS%.zip"
powershell -NoProfile -Command "$items = @('logs'); if(Test-Path 'dnasrep_test\dnasrep_443.log'){ $items += 'dnasrep_test\dnasrep_443.log' }; Compress-Archive -Path $items -DestinationPath '%OUT%' -Force"
if exist "%OUT%" (
  echo Saved %OUT%
) else (
  echo Could not create %OUT%
)
pause
