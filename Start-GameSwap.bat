@echo off
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -WindowStyle Hidden -Command "Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%~dp0GameSwap.ps1""'"
    exit /b
)
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0GameSwap.ps1"
if %errorlevel% neq 0 (
    echo.
    echo GameSwap s'est termine avec une erreur (code: %errorlevel%)
    pause
)
