Error resilience helpers — Core
=================================

This folder contains small runtime helpers for error recording and safe callback invocation.

Files
- `ErrorRecord.ahk` — lightweight model to construct serializable error records.
- `ErrorReporter.ahk` — writes JSONL records to `%LocalAppData%\AutoHotkey Workflow\Logs` and provides `Notify()` for non-modal alerts.
- `SafeCall.ahk` — wrapper to invoke functions safely, capture thrown values, report unexpected errors, and return structured results.
- `CallbackAdapters.ahk` — factory helpers to create hotkey/timer handlers that call `SafeCall` and notify on failures.

Rotation & redaction
- `ErrorReporter` now performs log rotation at ~2 MiB and retains the last 5 rotated files.
- Before writing a record, `ErrorReporter` redacts URLs, clipboard contents (if present), and simple `Secrets.*` tokens.

Quick usage

- Report a thrown value or message:

```ahk
#Include <Lib\Core\ErrorReporter>
ErrorReporter.Report(ErrorRecord.FromThrown("Something failed", { serviceId: "my_service" }))
```

- Show a non-modal notification (also logs a notification record):

```ahk
ErrorReporter.Notify("Operation completed", "My Service", "info", 4)
```

- Call a function safely:

```ahk
#Include <Lib\Core\SafeCall>
res := SafeCall("op.id", Func("DoWork"), { serviceId: "my_service" })
if (res.status != "success")
    ; handle failure

```

- Create a hotkey handler that is safe:

```ahk
#Include <Lib\Core\CallbackAdapters>
CapsLock.Hotkey("D", CallbackAdapters.MakeHotkeyHandler("op.insert", (*) => DoInsert(), { serviceId: "my_service" }))
```

Test harness

Run the test harness locally to verify logging and notification behavior:

```powershell
AutoHotkey.exe "Tests\Error Resilience\Test_ErrorReporter.ahk"
```

Notes
- The implementations are intentionally minimal for initial integration. They should be extended with structured fields, redaction, rotation, and retention policies as specified in `Error Plan/requirements.md`.
- Do not rely on `Notify()` for sensitive data; use `ErrorReporter.Report()` with sanitized `safeMessage` fields for logs.
