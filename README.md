# kim.xz OPTI WORKS V1.04

Original Windows 10/11 performance utility. Dark desktop GUI built with **HTML, CSS, JavaScript, .NET 8 WinForms/WebView2 and a PowerShell worker**. Not affiliated with Chris Titus Tech or Microsoft.

## Status: SOURCE RELEASE, Windows validation pending

This package contains source code, NOT a compiled installer or executable. The online launcher downloads a fixed source archive from GitHub, checks its pinned SHA-256 checksum, extracts it into the user profile, and builds on first run. The source was statically checked, but Windows execution, UAC, drive commands and GUI rendering cannot be verified in this Linux build environment. **Do not distribute as a production-verified optimizer until you test on Windows.**

## Run on Windows

Requirements: Windows 10/11, **.NET 8 SDK** (not just runtime), **Microsoft Edge WebView2 Runtime**, Windows PowerShell 5.1, internet during initial NuGet package restoration. The launcher DOES NOT fetch or execute remote PowerShell code. A signed public release and reproducible build should follow after testing.

1. Upload all ZIP contents to the GitHub repository first, preserving directories including `dist/`. Download **only** `Launch-kim.xz.bat` for a user PC, then double-click it. The BAT fetches the pinned archive from the repository and verifies the SHA-256 hash before extracting or building. Requires internet for first run and NuGet restore.
3. Approve UAC **only for explicit administrator-only operations** such as drive optimization, SFC, DISM or restore point.
4. Pick one of four modes or Manual Groups. The bottom bar shows status; Logs lists results. The app never assumes success merely because a command started.
5. User logs, jobs and backup live in `%LOCALAPPDATA%\kim.xz-opti-works`.

The BAT caches verified downloaded sources in `%LOCALAPPDATA%\kim.xz-opti-works\v1.04` and builds `src/KimXZ.OptiWorks/KimXZ.OptiWorks.csproj` in Release mode on the first run. Build from source manually with `dotnet build src/KimXZ.OptiWorks/KimXZ.OptiWorks.csproj -c Release`. The build requires access to NuGet to install the pinned Microsoft.Web.WebView2 package. To rebuild after source changes, delete `src/KimXZ.OptiWorks/bin/Release` before running the BAT.

## Modes

- Quick Boost: inventory, older user temporary files, DNS cache, startup inventory.
- Balanced Optimize: Quick tasks plus visual preference and storage diagnostics.
- Gaming Focus: inventory, temp/DNS, visuals, Game Mode user preference, startup and power reports.
- Deep Performance Tune: broader preset plus Windows Optimize-Volume on system NTFS volume; requires elevation. Drive optimization is **media-aware and managed by Windows**, not forced defragmentation.

Manual groups mirror the above. Elevated SFC, DISM and Restore Point are manual-only. No startup apps, drivers, services, updates, antivirus or firewall features are automatically disabled. No memory booster, claims of guaranteed FPS improvement, or aggressive registry debloat.

## Recovery

Before changing user settings, the worker stores a one-time settings baseline in `%LOCALAPPDATA%\kim.xz-opti-works\backups\original-settings.json`. The **RESTORE SAVED SETTINGS** button restores `VisualFXSetting`, `MenuShowDelay`, and `AutoGameModeEnabled` to values captured before the first change (including removal of previously absent registry values). Changes by the user between optimizations aren't tracked. Windows restore points are optional and may fail when System Protection is unavailable. Disk optimization, DNS clearing and temporary-file deletion cannot be undone by restoring registry settings.

## Troubleshooting

- **No .NET 8 SDK:** install the SDK from https://dotnet.microsoft.com/download/dotnet/8.0 and retry.
- **WebView2 missing:** install the WebView2 Runtime from Microsoft's official page.
- **Build errors:** ensure internet access to NuGet, use Windows PowerShell / .NET SDK and check the console output.
- **UAC canceled:** the action is not run and the UI reports it.
- **No output:** check local logs and jobs. Long SFC/DISM operations can take substantial time.
- **Drive optimization unavailable:** requires elevation, an NTFS system volume and the Windows Optimize-Volume command.
- **Settings seem unchanged:** visual choices may need sign out/in; Game Mode availability varies by Windows edition.
- **No obvious FPS improvement:** diagnose CPU/GPU thermal limits, RAM pressure, disk load and game settings. Cleaning DNS and temp files is maintenance, not an FPS mechanism.

## Security architecture

The app uses WebView2 `file:` UI and narrow JSON messages to a .NET native host. UI can only request predefined allowlisted tasks. The host generates per-job JSON definitions; the PowerShell worker independently validates allowlisted operation names. Job events are written as JSONL and polled by the host, so no web server is exposed. WebView2 DevTools are disabled in the release host but do not constitute a security boundary. Run only trusted builds. The worker does not download code or collect telemetry. Logs may include hardware names and local machine information; never publish those logs without reviewing them.

## References and license

Independent MIT-licensed implementation, copyright 2026 kim.xz OPTI WORKS contributors (see LICENSE). UI inspiration only: Chris Titus Tech WinUtil, https://github.com/ChrisTitusTech/winutil (MIT licensed). No WinUtil source or branding copied. Microsoft's Windows performance guidance: https://support.microsoft.com/en-us/windows/experience/performance-optimization/tips-to-improve-pc-performance-in-windows . Microsoft's powercfg documentation: https://learn.microsoft.com/en-us/windows-hardware/design/device-experiences/powercfg-command-line-options . Microsoft WebView2 Runtime/SDK is distributed under its own licensing terms; see https://developer.microsoft.com/microsoft-edge/webview2/ and NuGet package notices.

## Source tree

- `frontend/` HTML/CSS/JavaScript GUI.
- `src/KimXZ.OptiWorks/` .NET 8 WinForms + WebView2 host; launch + job control.
- `backend/worker.ps1` operation engine and JSONL logs.
- `assets/kx-logo.png` user-supplied KX artwork adapted into the UI.
- `tests/` static wiring tests; execute `python tests/test_wiring.py`.
- `docs/` implementation and testing notes.
- `Launch-kim.xz.bat` sole public launcher.

## GitHub upload

Delete the old repository source only **after** backing up/tagging the old version. Extract this ZIP and upload **all contents** (including nested folders), preserving their structure. Do not upload only the BAT. GitHub Pages is unnecessary for this native Windows application. Do not distribute only the `.bat` to end users until you publish a signed, built release bundle; the BAT downloads an archive from the designated GitHub repository only after checking its pinned SHA-256 digest. It does not pipe unverified code into PowerShell.
