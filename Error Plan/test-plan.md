# Error Resilience Test Plan

## Runner

The first implementation phase creates `Tests/Error Resilience/Run Error Tests.ahk`. It runs offline, uses temporary runtime/log folders and fixture scripts, returns exit code 0/1, and never changes real services or kills unrelated processes.

## Automated coverage

### Models and reporter

- `ErrorRecord` from AHK `Error` and non-`Error` values.
- Category/severity validation, stack/source extraction, safe fallback construction.
- Secret, credential, clipboard, argument, and URL redaction.
- JSONL write, fallback write, rotation, retention, fingerprint, and occurrence coalescing.
- Reporter/log/notification failure without recursion.

### Safe boundaries

- `SafeCall` success, every expected outcome, thrown values, fallback, duration, and reporter failure.
- Every callback adapter invokes exactly once and remains usable after failure.
- `OnError` reports without unsafe continuation or double-reporting.
- Intentional and unexpected `OnExit` classification.

### Manifest and validation

- Duplicate IDs, missing paths, invalid policies, profile filtering, and contradictions.
- Valid entrypoint and fixtures for syntax error, missing include, and initialization validation.
- Validate-all continues after failures and returns non-zero when any fail.
- Two-phase reload performs no replacement on failed preflight.

### Supervisor

- Normal/intentional exit, unexpected exit, startup timeout, exact-PID monitoring.
- Bounded restart delays, retry exhaustion, quarantine, stability reset, and manual recovery.
- Optional failure → degraded; critical failure → failed.
- Stale status cleanup and status-file atomicity.

### Regression/static checks

- Production manifest entries validate.
- Entrypoint directives are explicit.
- Migrated callback registrations use safe adapters.
- Production error `MsgBox`, empty catch, `ExitApp`, and recovery `Reload()` inventory reaches reviewed state.
- Minimal base contains no prohibited optional dependencies.

## Manual failure scenarios

Record date, profile/device, steps, observed state, relevant sanitized log fingerprint, and result for:

1. Action-like operation exception; later operation still works.
2. Hotkey, timer, GUI, clipboard, gesture, and tray callback failures.
3. Syntax error and missing include during reload; working service remains.
4. Service crash; only that service restarts.
5. Repeated crash; service quarantines without dialog storm.
6. Optional service failure; healthy hotkeys and profile switching remain.
7. Critical service failure; defined suite state appears.
8. Log and copied diagnostic contain no seeded sensitive values.
9. Supervisor exit; already-running children remain functional where supported.
10. Healthy/degraded startup, safe reload, profile switch, and suite exit.

## Traceability

A requirement passes only when a named test references its ID or a manual record supplies evidence. `verification.md` is populated during the final phase; unchecked narrative claims are not evidence.

