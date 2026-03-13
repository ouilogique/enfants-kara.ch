@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "SCRIPT=%SCRIPT_DIR%hugo_preview.ps1"

if not exist "%SCRIPT%" (
  echo Missing script: %SCRIPT%
  pause
  exit /b 1
)

start "" powershell.exe -NoExit -ExecutionPolicy Bypass -File "%SCRIPT%"
exit /b 0
