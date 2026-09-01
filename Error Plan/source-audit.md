# Source Audit — Initial Findings

Date: 2026-09-01

Patterns searched: `MsgBox`, `ExitApp`, `Reload()`, `throw`, `SetTimer`, `Hotkey`, `Hotstring`, `OnMessage`, `OnClipboard`, `OnExit`, `OnError`

Summary:

- Total matches found: 823
- Files matched: 117

Top-level observations:

- `MsgBox` and examples appear throughout examples and tools (Lib/Tools/**), some are user-facing utilities and tutorials.
- `throw` occurrences are common in libraries and robust input validation code (e.g., `Lib/Tools/OCR`, `Lib/Tools/UIA-v2`, `Apps Standalone/Screen Snipper`).
- `Reload()` and `ExitApp` are often used in tray menus and examples (e.g., `Startup Menu Tray.ahk`, dashboards, examples). Some production scripts add `Reload()` menu items.
- Callback registration (`Hotkey`, `SetTimer`, `OnMessage`, `.OnEvent`) is widely used in first-party apps and libraries.

Representative files with notable occurrences:

- `Apps Standalone/Screen Snipper/Screen Snipper.ahk` — `Reload()` in tray; `MsgBox` menu entries.
- `Apps Standalone/Screen Snipper/Screen Snipper OCR.ahk` — multiple `throw` uses in OCR logic.
- `Apps Integrated/Command Storer/Command Storer.ahk` — `ExitApp()` in tray menu handlers.
- `Dashboards/Age of Efficiency/Age Of Efficiency.ahk` — `Reload()` menu entry.
- `Lib/Extensions/Dark MsgBox.ahk` — custom MsgBox implementation used by core libraries.
- `Lib/Tools/UIA-v2/**` — many `throw` sites; some example files call `ExitApp` or `MsgBox`.

Initial classification guidance (next work for TASK-ERR-002):

- Treat `throw` in library code as intended error signaling — ensure these are captured by `SafeCall` or documented expected outcomes.
- Treat `MsgBox` in production entrypoints as potential blocking dialogs; each occurrence must be classified as `confirmation`, `info`, or `error` and migrated where required by REQ-MIG-001.
- `ExitApp` and `Reload()` in production entrypoints require classification: intentional lifecycle vs unexpected termination.
- Callback registrations must be migrated to safe adapters (`SafeCall`) so failure is contained per REQ-SAFE-005.

Next steps (to execute now if you confirm):

1. Produce per-file counts for `MsgBox`, `ExitApp`, `Reload()`, and `throw` restricted to production entrypoint scripts listed in `service-inventory.md`.
2. Start classifying occurrences in those production scripts and record decisions in `Error Plan/service-inventory.md` under `Source audits` or a dedicated per-service audit section.
3. Prepare repeatable `rg` commands used and store them in `Error Plan/tasks.md` verification steps.

Notes:

- Results include examples and tools; filtering will be required to focus on first-party production entrypoints vs examples/tutorials.
- I did not modify any production scripts. This file is a working artifact for TASK-ERR-002.

Per-service counts (initial batch) — matches for `MsgBox` / `ExitApp` / `Reload()` / `throw`:

| Service ID | Script path | MsgBox/ExitApp/Reload/throw matches |
|---|---|---|
| capslock_service | Apps Standalone\Capslock Service.ahk | 0 |
| age_of_efficiency | Dashboards\Age of Efficiency\Age Of Efficiency.ahk | 1 (Reload()) |
| macro_board | Dashboards\Macro Board\Macro Board.ahk | 1 (MsgBox placeholder) |
| desktops_manager | Apps Standalone\Desktops Manager\Desktops Manager.ahk | 0 |
| emoji_sender | Apps Standalone\Emoji Sender\Emoji Sender.ahk | 0 |
| mouse_gestures | Apps Standalone\Mouse Gestures\Mouse Gestures.ahk | 0 |
| screen_snipper | Apps Standalone\Screen Snipper\Screen Snipper.ahk | 6 (Reload(), multiple MsgBox()) |
| key_bindings | Apps Standalone\Key Bindings.ahk | 0 |
| text_speaker | Apps Standalone\Text Speaker.ahk | 3 (MsgBox: No voice/info) |
| window_manager | Apps Standalone\Window Manager.ahk | 0 |
| command_storer | Apps Integrated\Command Storer\Command Storer.ahk | 8 (ExitApp, Reload(), multiple MsgBox()) |
| app_hotkeys | Apps Integrated\App Hotkeys.ahk | 3 (MsgBox: Not implemented placeholders) |
| hotkeys | Apps Integrated\Hotkeys.ahk | 0 |
| mouse_toys | Apps Integrated\Mouse Toys.ahk | 0 |

Initial next actions:

- For scripts with `MsgBox` occurrences in production entrypoints (`screen_snipper`, `text_speaker`, `command_storer`, `macro_board`, `app_hotkeys`): classify each `MsgBox` as `confirmation`, `info`, `validation`, `error`, or `dev/demo`. Replace `error`/blocking dialogs with non-modal notifications or reporter calls per REQ-NOTIFY-001 and REQ-MIG-001.
- For `Reload()` and `ExitApp()` usages (`age_of_efficiency`, `screen_snipper`, `command_storer`): determine whether lifecycle operations are intentional or can occur unexpectedly; ensure they are intentionally triggered and documented; avoid unexpected `Reload()` during automated validation/replacement flows.
- For files with zero matches in this pattern set: run deeper audits for `throw`, empty `catch`, `ExitApp` via other constructs, and callback registrations (`Hotkey`, `.OnEvent`, `SetTimer`) to ensure safe adapters are applied.
- Produce a per-file detailed listing (line numbers and contexts) for the above scripts to prepare migration patches.

This is the end of the initial batch. Further automated classification will proceed file-by-file and produce suggested code changes for migration.
