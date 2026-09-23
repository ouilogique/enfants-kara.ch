@echo off
rem Double-clic ou ligne de commande : lance scripts/internal/preview.sh (Git Bash).
rem Prerequis : Git for Windows (Git Bash) et Hugo Extended.
rem Optionnel : qrencode pour afficher le QR code dans le terminal.
setlocal

set "BASH=%ProgramFiles%\Git\bin\bash.exe"
if not exist "%BASH%" set "BASH=%ProgramFiles(x86)%\Git\bin\bash.exe"
if not exist "%BASH%" set "BASH=%LOCALAPPDATA%\Programs\Git\bin\bash.exe"

if not exist "%BASH%" (
    echo Git Bash introuvable. Installez Git for Windows pour lancer la previsualisation.
    pause
    exit /b 1
)

pushd "%~dp0.." || (
    echo Impossible d’acceder au repertoire du projet.
    pause
    exit /b 1
)

"%BASH%" scripts/internal/preview.sh %*
set "EXIT_CODE=%ERRORLEVEL%"
popd

if not "%EXIT_CODE%"=="0" (
    echo.
    echo Le script s’est termine avec le code %EXIT_CODE%.
    pause
)
exit /b %EXIT_CODE%
