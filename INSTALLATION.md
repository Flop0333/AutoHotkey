# Installation and startup

## Requirements

- Windows 10 or 11.
- [AutoHotkey v2](https://www.autohotkey.com/) for the suite and tests.
- Microsoft Edge WebView2 Runtime for the dashboards and Text Speaker. Install it if it is missing; the loader DLLs are already in this repository.
- Windows PowerShell 5.1 or newer to run the test wrappers.

`Apps Standalone/Bluetooth Connect.ahk` is a legacy, optional AutoHotkey v1 script. It is not started by the main suite.

## First run

1. Clone or download the repository to any writable folder. Paths resolve from the checkout; it does not have to live under Documents.
2. Run `Startup/Startup.ahk` with AutoHotkey v2.
3. Check the AutoHotkey tray menu for the detected profile. Use **Profile** in that menu to switch it if necessary.
4. Fill only the local secret values needed by your chosen features.

The tray menu also provides **Reload**, **Log Dashboard**, **Test Dashboard**, and **Exit**. Exit stops all AutoHotkey processes, not only this suite.

## Profiles

Profiles let one checkout behave differently on work machines, personal laptops, and development environments.

- Definitions and device-name matching live in `Profiles/Profile Manager.ahk`.
- Get the current Windows device name with `MsgBox(A_ComputerName)` in an AHK script or `$env:COMPUTERNAME` in PowerShell.
- Add or adjust a `Profile` in the `Profiles` class, then use `ProfileManager.Is(...)` where behavior differs.
- The selected display name is saved in `Profiles/current_profile.ini`. This generated file is ignored by Git.
- At normal startup, the device name is checked again. An unmatched machine uses the `Default` profile.

The `Work` profile gets its device-name list from the local `WorkDeviceNames` secret. Other current device mappings are defined directly in the profile manager.

## Secrets

`Secrets/Secrets Catalog.ahk` is the tracked catalog of supported keys and descriptions. Personal values belong in `Secrets/My Secrets.json`, which is created and synchronized on startup and ignored by Git.

- Store values as one JSON object containing string keys and string values.
- New catalog keys are added to the local file with an empty value.
- Values whose catalog entry was removed are preserved locally in `Secrets/Removed Secrets.json`.
- Invalid JSON stops synchronization and leaves the original file untouched.
- Never commit either local secrets file. Do not place credentials directly in tracked scripts.

Most features tolerate empty values until that specific action is used.

## What starts automatically

`Startup/Startup.ahk` is the source of truth. It performs this sequence:

1. Build the tray menu and initialize structured logging.
2. Synchronize the local secrets files.
3. Select a requested profile or detect one from the computer name.
4. Start `Capslock Service.ahk` before scripts that register CapsLock hotkeys.
5. Start Age of Efficiency and Macro Board.
6. Start the configured standalone apps.
7. Start the configured integrated apps.

The exact current list is documented in the [app catalog](docs/APPS.md) and expressed by the `Run(...)` calls inside `RunStartup()`.

Logging initialization deletes the active `Logs/errors.log` and `Logs/errors.read` files. The Log Dashboard therefore shows the current suite session; earlier error sessions are not archived.

To change auto-run behavior, add, remove, or reorder those calls. Keep the CapsLock service ahead of its consumers.

## Start with Windows

Press `Win+R`, enter `shell:startup`, and create a shortcut there targeting the repository's `Startup/Startup.ahk`. Logging in to Windows will then launch the suite through that shortcut.

To disable automatic launch, remove the shortcut; the repository and settings remain intact. You can always run `Startup/Startup.ahk` manually.

## Optional environment override

Shared path resolution normally derives the repository root from `Lib/Core/Paths.ahk`. Set the `AUTOHOTKEY_BASE` environment variable only when a launcher or unusual include layout needs to override that location.

## Troubleshooting

- **A script opens with AutoHotkey v1:** confirm `.ahk` files are associated with AutoHotkey v2. The Bluetooth utility is the only intentional v1 exception.
- **A dashboard does not open:** install or repair Microsoft Edge WebView2 Runtime, then inspect the Log Dashboard.
- **The wrong profile is active:** select one from the tray menu and verify its device names in `Profiles/Profile Manager.ahk`.
- **A secret-backed action does nothing:** check that the matching key in `Secrets/My Secrets.json` contains a string value.
- **The suite behaves inconsistently after edits:** choose **Reload** from the tray menu.
- **Before reporting a code problem:** run `./Tests/Invoke-AllTests.ps1`; see the [testing guide](docs/TESTING.md).
