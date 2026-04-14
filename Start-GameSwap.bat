@echo off
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Demande de privileges administrateur...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0GameSwap.ps1"
if %errorlevel% neq 0 (
    echo.
    echo GameSwap s'est termine avec une erreur (code: %errorlevel%)
    pause
)
