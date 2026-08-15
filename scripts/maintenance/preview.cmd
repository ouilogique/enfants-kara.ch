@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "SCRIPT=%SCRIPT_DIR%preview.ps1"
set "POWERSHELL_7=%ProgramFiles%\PowerShell\7\pwsh.exe"

if not exist "%SCRIPT%" (
  echo Missing script: %SCRIPT%
  pause
  exit /b 1
)

if not exist "%POWERSHELL_7%" (
  echo Missing PowerShell 7 executable: %POWERSHELL_7%
  pause
  exit /b 1
)

start "" "%POWERSHELL_7%" -NoExit -ExecutionPolicy Bypass -File "%SCRIPT%"
exit /b 0
