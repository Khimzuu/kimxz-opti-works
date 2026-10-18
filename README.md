# kim.xz opti works

Windows 10/11 maintenance utility with a PowerShell menu. Requires Windows PowerShell 5.1+.

## Start from GitHub

Review the source first. After publishing to a public repository with your GitHub username:

```powershell
irm https://raw.githubusercontent.com/YOUR_USERNAME/kimxz-opti-works/main/win.ps1 | iex
```

This runs live code from the GitHub `main` branch. **For reproducible and safer execution**, review a particular commit and use its immutable raw URL (replace `COMMIT_SHA`):

```powershell
irm https://raw.githubusercontent.com/YOUR_USERNAME/kimxz-opti-works/COMMIT_SHA/win.ps1 | iex
```

**Do not run unreviewed scripts as administrator.** Some menu commands require elevation and prompt separately for confirmation. The startup command does not automatically elevate. No measurable FPS benefit is guaranteed.

## Offline use

Download or clone this repository. Run `Launch-kim.xz-opti.bat`, optionally as administrator for SFC, DISM, networking repair, and other admin actions. The batch file runs `kim.xz-opti.ps1` locally without bypassing execution policy.

## Logs and changes

Session logs and settings backups are stored under `%LOCALAPPDATA%\kim.xz-opti-works`. Registry backup exports only HKCU and is not a complete system backup. Resetting networking can disrupt connectivity, and power-plan changes can increase heat and power usage. See prompts shown before each consequential change.

## Validation status

Reviewed statically; Windows runtime test **not yet performed**. Test on a disposable Windows VM before promoting it for public, administrator-level use.
