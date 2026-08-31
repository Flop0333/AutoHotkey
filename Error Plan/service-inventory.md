# Production Service Inventory

TASK-001 populates this file from the current repository before manifest implementation.

## Required columns

| Service ID | Display name | Script path | Profile rules | Category | Criticality | Persistent | Single instance | Tray owner | Startup work | Callback types | Current error paths | Dependencies | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|

## Entrypoints

| Service ID | Display name | Script path | Profile rules | Category | Criticality | Persistent | Single instance | Tray owner | Startup work | Callback types | Current error paths | Dependencies | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| _inventory pending_ | | | | | | | | | | | | | |

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

## Source audits

TASK-002 records first-party production occurrences and classification decisions for:

- `MsgBox` (confirmation, information, validation, error, development/demo).
- `throw` and expected catch boundary.
- Empty `catch` and silent `try`.
- `ExitApp` and `Reload()`.
- Hotkey/hotstring, timer, GUI, clipboard, menu, gesture, message, and other callbacks.
- Static class initialization and auto-execute work.
- Broad `Core.ahk` includes and include cycles.

