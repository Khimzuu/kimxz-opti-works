# kim.xz opti works V3

Windows 10/11 PowerShell 5.1 desktop maintenance utility. Three first-screen routes:

- **Standard Optimize**: system information, disk space report, remove eligible temp files older than 48 hours, flush DNS.
- **Advanced Optimize**: Standard plus visual-effects preference, Game Mode user setting, Windows drive optimization, and Defender status. It does **not** run every risky manual tool.
- **Manual**: choose individual repairs, network reset, Recycle Bin removal, status, backup, and Windows settings controls.

## Local usage

Keep `kimxz-v3.ps1` and `kimxz-worker.ps1` together. Double-click `Launch-kim.xz-V3.bat`. The GUI executes a separate background PowerShell worker and polls a JSON status file. Logs live in `%LOCALAPPDATA%\kim.xz-opti-works\logs`. Tools requiring elevation instruct users to relaunch as admin. No invisible admin elevation.

## Online usage

The separate `Launch-kim.xz-Online.bat` downloads exactly these two `.ps1` files from a version-pinned GitHub commit, validates their SHA-256 hashes, and opens the GUI. It does not use `iex`. To upgrade the online launcher, regenerate it with the new commit and hashes.

## Safety and limits

No telemetry, no automatic installation, no Defender or Windows Update disabling, and no permanent changes to OS security. Some operations (network reset, Recycle Bin clearing) cannot be undone and are excluded from presets. This software has **not been Windows-tested** in the authoring environment. Validate in a VM and on a noncritical device before public release. Not a guaranteed FPS increase. Benchmark 1% lows and frame times before and after. Large gains on low-end PCs often require managing thermal throttling, startup apps, game resolution, or hardware constraints.

## References

- Microsoft: https://support.microsoft.com/en-us/windows/experience/performance-optimization/tips-to-improve-pc-performance-in-windows
- Microsoft: https://support.microsoft.com/en-us/windows/hardware/display-graphics/optimizations-for-windowed-games-in-windows-11
- Microsoft: https://support.microsoft.com/en-us/windows/security/windows-security/stay-protected-with-the-windows-security-app
