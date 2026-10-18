@echo off
setlocal EnableExtensions
set "APPHOME=%LOCALAPPDATA%\kim.xz-opti-works\v1.04"
set "ZIPFILE=%TEMP%\kimxz-v1.04-source.zip"
set "SOURCE=https://raw.githubusercontent.com/Khimzuu/kimxz-opti-works/main/dist/kimxz-v1.04-source.zip"
title kim.xz OPTI WORKS V1.04 - verified online launcher
echo kim.xz OPTI WORKS V1.04 - checking signed-off source archive hash...
where powershell.exe >nul 2>&1 || (echo ERROR: Windows PowerShell not found.& pause & exit /b 1)
where dotnet.exe >nul 2>&1 || (echo ERROR: .NET 8 SDK required from https://dotnet.microsoft.com/download/dotnet/8.0 & pause & exit /b 1)
dotnet --list-sdks | findstr /R "^8\." >nul || (echo ERROR: .NET 8 SDK not installed.& pause & exit /b 1)
if not exist "%APPHOME%\src\KimXZ.OptiWorks\KimXZ.OptiWorks.csproj" (
 echo Downloading verified source from GitHub...
 powershell.exe -NoProfile -Command "try { Invoke-WebRequest -Uri '%SOURCE%' -OutFile '%ZIPFILE%' -UseBasicParsing -ErrorAction Stop } catch { Write-Host $_.Exception.Message;exit 1 }"
 if errorlevel 1 (echo ERROR: Could not download release source.& pause & exit /b 1)
)
if exist "%ZIPFILE%" (
 powershell.exe -NoProfile -Command "if ((Get-FileHash -Algorithm SHA256 -LiteralPath '%ZIPFILE%').Hash -ne '125148C63BDD9FB383CE2C78A40BF5A2D13AC80627DB190E18207E33642C4B78') {exit 1}"
 if errorlevel 1 (echo ERROR: Source archive hash mismatch. Refusing to execute.& del "%ZIPFILE%" >nul 2>&1 & pause & exit /b 1)
 powershell.exe -NoProfile -Command "New-Item -ItemType Directory -Force -Path '%APPHOME%' | Out-Null; Expand-Archive -LiteralPath '%ZIPFILE%' -DestinationPath '%APPHOME%' -Force -ErrorAction Stop"
 if errorlevel 1 (echo ERROR: Source archive extraction failed.& pause & exit /b 1)
 del "%ZIPFILE%" >nul 2>&1
)
set "EXE=%APPHOME%\src\KimXZ.OptiWorks\bin\Release\net8.0-windows\KimXZ.OptiWorks.exe"
if not exist "%EXE%" (
 echo Building verified V1.04 source...
 dotnet build "%APPHOME%\src\KimXZ.OptiWorks\KimXZ.OptiWorks.csproj" -c Release --nologo
 if errorlevel 1 (echo ERROR: Build failed. Check NuGet internet access and WebView2 Runtime.& pause & exit /b 1)
)
start "" "%EXE%"
if errorlevel 1 (echo ERROR: Could not start optimizer.& pause & exit /b 1)
exit /b 0
