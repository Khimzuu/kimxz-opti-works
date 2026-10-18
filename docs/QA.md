# V1.04 Windows QA checklist (not yet executed on Windows)

1. Windows 10 and Windows 11, 100% and 150% scaling: launcher first build, WebView2 window, no crop, navigation.
2. Start Quick, Balanced, Gaming, Deep once and twice; inspect per-step events and exit status.
3. Disconnect network after first build; verify GUI startup without remote dependencies.
4. Reject UAC for Deep and SFC; confirm no success and UI receives error.
5. Observe progress during running SFC or DISM; interface must remain responsive.
6. Run Undo; verify all captured settings restored (including absent-value removal).
7. Confirm temp cleanup only touches files older than 24 hours in current user TEMP.
8. Verify low-storage and HDD/SSD devices; confirm Windows Optimization is media-aware.
9. Verify when System Protection disabled: restore-point failure, not success.
10. Validate reports with PowerShell console, event JSONL, log persistence and repeated execution.
11. Ensure Defender/Windows Update state unchanged.
12. Validate install with non-admin standard user; only explicit admin tasks prompt UAC.

Static tests are NOT substitutes for Windows system testing. No binary release should claim these tests pass before a Windows test run.
