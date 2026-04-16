@echo off
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Demande de privileges administrateur...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0GameSwap.ps1"
if %errorlevel% neq 0 (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
        "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null; [System.Windows.Forms.MessageBox]::Show('GameSwap s''est termine avec une erreur (code: %errorlevel%).`n`nConsultez les logs pour plus de details.', 'Erreur GameSwap', 'OK', 'Error')"
)
