@echo off
setlocal
chcp 65001 >nul
title kim.xz opti works
cd /d "%~dp0"
where powershell.exe >nul 2>&1
if errorlevel 1 (
  echo Windows PowerShell was not found.
  pause
  exit /b 1
)
powershell.exe -NoLogo -NoProfile -File "%~dp0kim.xz-opti.ps1"
if errorlevel 1 (
  echo.
  echo Utility exited with an error.
  pause
)
