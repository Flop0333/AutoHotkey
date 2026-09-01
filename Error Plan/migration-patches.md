# Migration patches (suggested) — non-destructive proposals

Date: 2026-09-01

This file records suggested small patches to migrate blocking `MsgBox`/`Reload()`/`ExitApp()` usages in production entrypoints to the new error/reporting infrastructure. These are proposals only and should be applied one-at-a-time after review.

1) `Apps Standalone\Text Speaker.ahk` — replace blocking error dialog

- Before:

```ahk
if voice = "" {
    MsgBox("No voice found", "Error", "Iconi T1")
    return
}
```

- Suggested after (non-modal, logged):

```ahk
if voice = "" {
    ErrorReporter.Notify("No voice found", "Text Speaker", "error")
    ErrorReporter.Report(ErrorRecord.FromThrown("No voice found", { serviceId: "text_speaker", category: "validation", severity: "error", safeMessage: "No voice available" }))
    return
}
```

2) `Apps Standalone\Screen Snipper\Screen Snipper.ahk` — menu items that call `MsgBox()` or `Reload()`:

- Replace `MsgBox()` menu entries with `ErrorReporter.Notify(...)` for informational items.
- Replace a `Reload()` that is used to avoid errors with a no-op or controlled reload after preflight validation; discussion required.

3) `Apps Integrated\Command Storer\Command Storer.ahk` — validations and `ExitApp`:

- `MsgBox` used for invalid input should be replaced with `ErrorReporter.Notify` and validation return codes.
- `ExitApp()` in tray menu is an intentional lifecycle operation; keep but document in manifest as intentional lifecycle.

4) `Dashboards\Macro Board\Macro Board.ahk` and `Apps Integrated\App Hotkeys.ahk` — dev/demo placeholders should be replaced with `ErrorReporter.Notify` or removed prior to production release.

How to apply a single patch (example):

1. Create a focused branch.
2. Apply the change to the file.
3. Run `Tests/Error Resilience/Test_ErrorReporter.ahk` manually to ensure logging works.
4. Run local smoke tests for the modified script (manually start/trigger affected flows).
5. Commit with rationale and update `Error Plan/verification.md` with evidence.

Notes:
- These patches intentionally avoid changing semantics other than replacing blocking dialogs with non-modal notifications plus explicit reporting. For `Reload()`/`ExitApp()`, human review is required to determine if lifecycle semantics are being altered.
