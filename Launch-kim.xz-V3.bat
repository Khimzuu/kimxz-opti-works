@echo off
setlocal
cd /d "%~dp0"
title kim.xz opti works V3
powershell.exe -NoProfile -STA -File "%~dp0kimxz-v3.ps1"
if errorlevel 1 (
  echo Failed to launch the GUI. Please check that kimxz-v3.ps1 is in the same folder.
  pause
)
endlocal
