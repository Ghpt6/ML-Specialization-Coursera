@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\start-lab.ps1" %*
set "lab_result=%ERRORLEVEL%"
if not "%lab_result%"=="0" pause
exit /b %lab_result%
