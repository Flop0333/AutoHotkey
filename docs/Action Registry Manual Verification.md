# Action Registry Manual Verification

Automated tests cover registry contracts, action references, parsing, safety policy, and failure isolation. The checks below intentionally remain manual because they launch real applications, replace running AutoHotkey scripts, move windows, or can affect the computer session.

Record the date, machine, profile, and result for each run. Do not mark an unavailable profile as passed; record it as unavailable with the reason.

## Before Testing

- Ensure the normal local `Secrets/Secrets.ahk` is present and contains the values required by this machine.
- Save work in applications that may be closed or moved.
- Run `Tests/RunRegistryTests.ahk` and `Tests/ValidateActionReferences.ps1`.
- Confirm all `Tests/Compile*.ahk` harnesses pass.

## Per-Profile Clean Start

Repeat for Work, Dev Box, Woonkamer Laptops, and Default:

- Select the profile from the Startup tray and allow the suite to restart.
- Confirm Startup, Age of Efficiency, Macro Board, hotkeys, gestures, Screen Snipper, Window Manager, and Desktop Manager start without an unhandled error.
- Open Age of Efficiency and confirm only eligible actions are shown.
- Open Macro Board and confirm the expected profile buttons, icons, tooltips, and toggle states.
- Confirm an unavailable optional application does not prevent unrelated tools from working.

## Interaction Checks

- Invoke every Age of Efficiency app command from the migration inventory. Cancel at least one argument prompt.
- Verify `y` and `Maps` open bookmarks without arguments and search with arguments.
- Click every Macro Board button. Confirm toggle state changes immediately and refreshes after hiding/showing the board.
- Exercise each migrated hotkey and mouse gesture once. Confirm the action fires once and only in its intended window context.
- Exercise Screen Snipper copy, copy-only, save-only, and OCR modes.
- Exercise Desktop Manager previous/pin and configured application-launch actions.
- Cancel shutdown, kill-AHK, and close-browser confirmations. Confirm nothing destructive happens and no failure is reported.
- Reopen dashboards, switch profiles, reload scripts, and trigger one safe action failure to confirm the suite remains usable.

## Test Record

| Date | Machine | Profile | Result | Notes / unavailable reason |
|---|---|---|---|---|
| 2026-08-31 | LAPTOP-LNTJIJKB | Work | Startup passed | 14 processes; dashboards initialized; interaction checks pending. |
| 2026-08-31 | LAPTOP-LNTJIJKB | Dev Box | Startup passed | 15 processes plus one late starter; no error window; interaction checks pending. |
| 2026-08-31 | LAPTOP-LNTJIJKB | Woonkamer Laptops | Startup passed | 15 processes; dashboards initialized; interaction checks pending. |
| 2026-08-31 | LAPTOP-LNTJIJKB | Default | Startup passed | 15 processes; dashboards initialized; interaction checks pending. |
