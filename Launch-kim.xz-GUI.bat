@echo off
setlocal
cd /d "%~dp0"
title kim.xz opti works v2 - GUI Launcher
powershell.exe -NoProfile -STA -File "%~dp0kimxz-gui.ps1"
if errorlevel 1 (
  echo.
  echo The GUI did not launch. Review the PowerShell error above.
  pause
)
endlocal
