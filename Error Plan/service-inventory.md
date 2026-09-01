# Production Service Inventory

TASK-001 populates this file from the current repository before manifest implementation.

## Required columns

| Service ID | Display name | Script path | Profile rules | Category | Criticality | Persistent | Single instance | Tray owner | Startup work | Callback types | Current error paths | Dependencies | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|

## Entrypoints

| Service ID | Display name | Script path | Profile rules | Category | Criticality | Persistent | Single instance | Tray owner | Startup work | Callback types | Current error paths | Dependencies | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| capslock_service | Capslock Service | Apps Standalone\Capslock Service.ahk | all profiles | app | low | yes | yes | none | initializes capslock hotkey | hotkey | TBD | none | Inferred from Startup/Startup.ahk; verify script metadata |
| capslock_service | Capslock Service | Apps Standalone\Capslock Service.ahk | all profiles | app | low | yes | yes | none | initializes capslock hotkey | hotkey | No blocking `MsgBox`/`ExitApp`/`Reload()` detected (0 matches); still verify Hotkey adapters | none | Inferred from Startup/Startup.ahk; verify script metadata |
| age_of_efficiency | Age Of Efficiency | Dashboards\Age of Efficiency\Age Of Efficiency.ahk | all profiles | dashboard | medium | yes | yes | none | dashboard UI and inputs | GUI, hotkeys | `Reload()` tray menu (intentional lifecycle) | none | Inferred from Startup/Startup.ahk |
| macro_board | Macro Board | Dashboards\Macro Board\Macro Board.ahk | all profiles | dashboard | medium | yes | yes | none | macro board UI/controller | GUI, hotkeys | `MsgBox` used in profile button (dev/demo) | none | Inferred from Startup/Startup.ahk |
| desktops_manager | Desktops Manager | Apps Standalone\Desktops Manager\Desktops Manager.ahk | all profiles | utility | low | yes | yes | none | virtual desktop management | hotkeys, UI | No blocking `MsgBox`/`ExitApp`/`Reload()` detected (0 matches); verify callback registration safety | none | Inferred from Startup/Startup.ahk |
| emoji_sender | Emoji Sender | Apps Standalone\Emoji Sender\Emoji Sender.ahk | all profiles | utility | low | yes | yes | none | clipboard/typing helper | hotkeys | No blocking `MsgBox`/`ExitApp`/`Reload()` detected (0 matches) | none | Inferred from Startup/Startup.ahk |
| mouse_gestures | Mouse Gestures | Apps Standalone\Mouse Gestures\Mouse Gestures.ahk | all profiles | utility | low | yes | yes | none | gesture detection and mapping | mouse events, hotkeys | No blocking `MsgBox`/`ExitApp`/`Reload()` detected (0 matches) | none | Inferred from Startup/Startup.ahk |
| screen_snipper | Screen Snipper | Apps Standalone\Screen Snipper\Screen Snipper.ahk | all profiles | utility | low | yes | yes | none | screenshot + OCR | GUI, clipboard | `Reload()` in tray/context; multiple `MsgBox()` in menu/context (blocking) — migrate to non-modal notifications | none | Inferred from Startup/Startup.ahk |
| key_bindings | Key Bindings | Apps Standalone\Key Bindings.ahk | all profiles | utility | low | yes | yes | none | global key bindings | hotkeys | No blocking `MsgBox`/`ExitApp`/`Reload()` detected (0 matches); verify hotkey migration needs | none | Inferred from Startup/Startup.ahk |
| text_speaker | Text Speaker | Apps Standalone\Text Speaker.ahk | all profiles | utility | low | yes | yes | none | TTS helper | hotkeys, clipboard | `MsgBox("No voice found")` (blocking error dialog) and other informational `MsgBox()` usages — error dialog requires migration | none | Inferred from Startup/Startup.ahk |
| window_manager | Window Manager | Apps Standalone\Window Manager.ahk | all profiles | utility | low | yes | yes | none | window management utilities | hotkeys | No blocking `MsgBox`/`ExitApp`/`Reload()` detected (0 matches); verify drag/hotkey adapters | none | Inferred from Startup/Startup.ahk |
| command_storer | Command Storer | Apps Integrated\Command Storer\Command Storer.ahk | all profiles | integrated | low | yes | yes | none | store/replay commands | hotkeys, storage | `ExitApp()` in tray (intentional); `MsgBox()` used for validation/confirmation; `Reload()` on config changes — classify validation vs lifecycle and migrate blocking error dialogs | none | Inferred from Startup/Startup.ahk |
| app_hotkeys | App Hotkeys | Apps Integrated\App Hotkeys.ahk | all profiles | integrated | low | yes | yes | none | integrated hotkeys definitions | hotkeys | `MsgBox("Not implemented")` placeholders (dev/demo) | none | Inferred from Startup/Startup.ahk |
| hotkeys | Hotkeys | Apps Integrated\Hotkeys.ahk | all profiles | integrated | low | yes | yes | none | shared hotkeys for apps | hotkeys | No blocking `MsgBox`/`ExitApp`/`Reload()` detected (0 matches); verify safe adapters usage | none | Inferred from Startup/Startup.ahk |
| mouse_toys | Mouse Toys | Apps Integrated\Mouse Toys.ahk | all profiles | integrated | low | yes | yes | none | small mouse utilities | mouse events, hotkeys | No blocking `MsgBox`/`ExitApp`/`Reload()` detected (0 matches) | none | Inferred from Startup/Startup.ahk |

## Baseline scenarios

Record commands/steps and current observable behavior for:

- Full startup.
- Full reload.
- Per-service restart where currently possible.
- Profile switch.
- Suite exit.
- Expected cancellation/unavailability.
- Recoverable callback failure.
- Unhandled runtime failure.
- Load-time validation failure.
- Child process crash.

### Observed / inferred baseline (work in progress)

- Full startup: `RunStartup()` (invoked automatically when `Startup.ahk` runs from the Startup folder) calls `Run()` for each listed script, launching each as a separate process. Expected result: separate AHK processes start for each entry, no manifest/supervisor present yet.
- Full reload: no centralized reload implemented; scripts may implement their own `Reload()` semantics. Replacing running scripts is manual.
- Per-service restart: currently manual — terminate the target process to restart it; no supervisor enforces exact-PID restarts.
- Profile switch: handled via `Profile Manager`; expected to trigger profile-specific behavior and possibly restarts via per-script logic.
- Suite exit: no global supervisor; exiting `Startup.ahk` does not automatically terminate child processes launched with `Run()`.
- Recoverable callback failure: unknown per-script; assume many errors currently trigger `MsgBox` or process termination — to be audited in TASK-ERR-002.
- Unhandled runtime failure: process exits; no quarantine or bounded restart present in current codebase.
- Load-time validation failure: not enforced before replacement; TODO: implement `Validate` checks per REQ-VAL-001.
- Child process crash: observed behavior is process exit; no automatic supervisor restart.

**Assumptions:** Entries inferred directly from `Startup/Startup.ahk`. Criticality, profile rules, callback types, and current error paths are best-effort and require per-script confirmation during TASK-ERR-002. No production files were modified.

## Next Steps

- Verify each listed script path exists and record file-specific metadata.
- Run `rg` searches for `MsgBox`, `ExitApp`, `Reload()`, `throw`, and callback registrations to populate the source audit (TASK-ERR-002).

## Source audits

TASK-002 records first-party production occurrences and classification decisions for:

- `MsgBox` (confirmation, information, validation, error, development/demo).
- `throw` and expected catch boundary.
- Empty `catch` and silent `try`.
- `ExitApp` and `Reload()`.
- Hotkey/hotstring, timer, GUI, clipboard, menu, gesture, message, and other callbacks.
- Static class initialization and auto-execute work.
- Broad `Core.ahk` includes and include cycles.

