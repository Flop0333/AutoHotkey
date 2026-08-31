# Error Resilience Requirements

Tasks and tests reference these stable IDs.

## Entrypoints and validation

- **REQ-ENTRY-001** — Every production entrypoint has a stable service ID, display name, category, criticality, profile rule, script path, startup timeout, restart policy, and health policy.
- **REQ-ENTRY-002** — Every entrypoint explicitly declares AHK v2, single-instance behavior, and tray ownership.
- **REQ-ENTRY-003** — The manifest rejects duplicate IDs, missing scripts, contradictory profiles, and invalid policies.
- **REQ-VAL-001** — Enabled entrypoints are checked with the production AHK v2 interpreter using `/Validate /ErrorStdOut`.
- **REQ-VAL-002** — Validation returns structured results with entrypoint, included file, line, message, and exit code where available.
- **REQ-VAL-003** — One invalid entrypoint does not prevent validation of the others.
- **REQ-VAL-004** — Full reload, per-service reload, and profile transition validate targets before replacing working processes.
- **REQ-VAL-005** — Failed validation leaves the current valid processes unchanged.

## Error records and reporting

- **REQ-ERR-001** — Unexpected failures become safely constructed `ErrorRecord` values.
- **REQ-ERR-002** — Records include time, severity, category, service ID, operation ID, safe message, error type/message, `What`, file, line, stack, mode, duration, and fingerprint when available.
- **REQ-ERR-003** — Categories cover validation, initialization, invocation, callback, dependency, process exit, and supervisor failure.
- **REQ-ERR-004** — `ErrorReporter.Report()` is the single first-party unexpected-failure recording path.
- **REQ-ERR-005** — Reporter failure is non-recursive and cannot crash the caller.
- **REQ-ERR-006** — Logs use JSON Lines under local application data with a plain-text fallback.
- **REQ-ERR-007** — Logs rotate at 2 MiB, retain five files, and flush important records promptly.
- **REQ-ERR-008** — Secrets, credentials, clipboard text, raw arguments, and sensitive URL values are redacted by default.
- **REQ-ERR-009** — Fingerprints group repeated failures and notifications coalesce repeated occurrences.

## User notification

- **REQ-NOTIFY-001** — Unexpected production errors never use a blocking `MsgBox` or default AHK error dialog.
- **REQ-NOTIFY-002** — Error notices are non-modal, auto-closing, sanitized, and rate-limited.
- **REQ-NOTIFY-003** — Native tray notification is the fallback when preferred UI is unavailable.
- **REQ-NOTIFY-004** — Confirmations remain distinct from error reporting.
- **REQ-NOTIFY-005** — Degraded status remains visible after transient notifications close.

## Invocation containment

- **REQ-SAFE-001** — `SafeCall` accepts stable operation ID, callable, optional context, and arguments.
- **REQ-SAFE-002** — It catches AHK `Error` and non-`Error` thrown values and returns a structured result.
- **REQ-SAFE-003** — Expected cancellation, validation, and unavailability bypass unexpected-error reporting.
- **REQ-SAFE-004** — Unexpected failures are never silently swallowed.
- **REQ-SAFE-005** — Safe adapters exist for hotkeys/hotstrings, timers, GUI/control events, clipboard, menus, gestures, and other production callbacks.
- **REQ-SAFE-006** — Failure in a migrated callback ends only that invocation; later invocations still work.

## Global fallback and lifecycle

- **REQ-GLOBAL-001** — Minimal service bootstrap registers `OnError` before optional components initialize.
- **REQ-GLOBAL-002** — `OnError` handles `Error` and non-`Error` thrown values, reports safely, suppresses blocking dialogs, and never requests unsafe continuation.
- **REQ-GLOBAL-003** — The fallback performs no slow network, WebView, UIA, or modal work.
- **REQ-GLOBAL-004** — `OnExit` distinguishes intentional stop, reload, profile transition, single-instance replacement, shutdown, and unexpected exit.
- **REQ-GLOBAL-005** — Failures already contained by `SafeCall` are not double-reported.

## Service runtime and supervisor

- **REQ-SVC-001** — Services report `starting`, `ready`, `degraded`, `stopping`, and `failed` with service ID and PID.
- **REQ-SVC-002** — Supervisor represents `disabled`, `starting`, `ready`, `degraded`, `stopped`, `failed`, `restarting`, and `quarantined`.
- **REQ-SVC-003** — Local status transport requires no network service and removes stale PID state.
- **REQ-SVC-004** — Persistent services report ready only after essential initialization succeeds.
- **REQ-SVC-005** — Optional initialization failure produces degraded state; essential failure produces failed state.
- **REQ-SVC-006** — Supervisor monitors exact captured PIDs and startup timeouts.
- **REQ-SVC-007** — Restart affects only the failed service and is bounded by attempts, increasing delay, time window, and stability reset.
- **REQ-SVC-008** — Exhausted retry budget quarantines the service without a dialog storm.
- **REQ-SVC-009** — Intentional lifecycle operations do not consume retries or trigger restarts.
- **REQ-SVC-010** — Optional failure makes the suite degraded; critical failure produces failed state.
- **REQ-SVC-011** — Automatic recovery never kills all AHK processes.
- **REQ-SVC-012** — Manual validate/start/stop/restart and restart-failed operations are available.

## Startup UI and dependencies

- **REQ-UI-001** — Startup tray is generated from the manifest and displays overall and per-service state.
- **REQ-UI-002** — Tray exposes validation, safe reload, per-service recovery, logs, and sanitized latest failure.
- **REQ-UI-003** — Profile switching and suite exit remain available in degraded state.
- **REQ-DEP-001** — Process directives live in entrypoints, not shared libraries.
- **REQ-DEP-002** — A minimal base contains only paths, service context, error infrastructure, and stable process setup.
- **REQ-DEP-003** — Optional WebView, UIA, desktop, and app integrations are excluded from the minimal base.
- **REQ-DEP-004** — Optional integrations use explicit initialization rather than failure-prone include-time initialization where practical.
- **REQ-DEP-005** — Production entrypoints migrate from broad `Core.ahk` includes to narrow modules before compatibility removal.

## Migration and quality

- **REQ-MIG-001** — First-party production error `MsgBox` calls migrate to expected outcomes or structured reporting; confirmations remain.
- **REQ-MIG-002** — Empty catches, silent tries, `ExitApp`, and recovery `Reload()` calls are reviewed and classified.
- **REQ-MIG-003** — Intentionally ignored cleanup failures contain an explanatory comment.
- **REQ-QUAL-001** — Startup, hotkeys, dashboards, profile switching, service recovery, reload, and exit regressions pass on supported profiles.
- **REQ-QUAL-002** — Reporter remains functional without optional UI, WebView, UIA, internet, apps, or profile persistence.
- **REQ-QUAL-003** — Diagnostics identify service, operation, source, occurrence, and time without exposing sensitive data.

