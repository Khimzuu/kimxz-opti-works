# kim.xz opti works v2 — Desktop GUI (Windows 10/11)

A local-only Windows Forms interface for Windows PowerShell 5.1.

## Run
1. Extract the entire ZIP into a folder.
2. Double-click `Launch-kim.xz-GUI.bat`.
3. Choose a maintenance action. Actions requiring administrator rights request a UAC prompt when necessary.
4. The selected action runs in a separate console and writes a log to `%LOCALAPPDATA%\kim.xz-opti-works\logs`.

## Files
- `kimxz-gui.ps1` — desktop UI
- `kimxz-actions.ps1` — action runner
- `Launch-kim.xz-GUI.bat` — launcher
- `legacy-console.ps1` — original terminal version for reference

## Important
No downloads or telemetry. Windows security settings are not disabled. A performance preset is not a guaranteed FPS increase. Running temp cleanup could remove older temporary files still needed by running applications. Emptying the Recycle Bin is irreversible. A network reset can disrupt VPNs and custom IP configurations. Test on a noncritical Windows machine and inspect all scripts before use. Actual Windows execution was not available in the build environment.

To publish on GitHub, upload these files in your repository. The current `irm .../win.ps1 | iex` still launches V1 until you deliberately change `win.ps1`. For GUI deployment, **do not** pipe the GUI source into `iex` because its adjacent action file is required; distribute a versioned ZIP and verify a hash.
