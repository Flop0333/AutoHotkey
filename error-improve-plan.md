# Error Resilience Improvement Plan

## Purpose

Make the AutoHotkey suite resilient to failures so that one broken action, callback, include, or service does not unnecessarily interrupt unrelated functionality.

This plan is the authoritative checklist for the work. The implementation is complete only when every task is checked, every acceptance specification passes, and the final failure-scenario test has been performed.

## Scope

This plan covers:

- AutoHotkey v2 production entrypoints launched by the startup suite.
- Load-time failures such as syntax errors, invalid includes, and static initialization failures.
- Runtime failures in actions, hotkeys, timers, GUI events, clipboard events, gestures, and startup code.
- Error logging, safe user notifications, service status, restart behavior, and diagnostics.
- Reducing the failure radius caused by the broad `Lib/Core.ahk` dependency graph.
- Integrating error handling with `ActionRegistry` and `ActionResult`.

Bundled third-party examples are outside scope unless production code executes or includes them. Expected user confirmations are not errors and may remain modal.

## Guiding Decisions

- The suite targets AutoHotkey v2 only.
- A production error must not open a blocking error `MsgBox` unless continuing would be unsafe and no non-modal reporting path is available.
- Confirmation dialogs for destructive or sensitive actions may remain blocking.
- Arbitrary execution must not continue after an unhandled runtime error. The failed invocation or AHK event thread should end cleanly.
- Process isolation remains the primary boundary between independent services.
- `try/catch` at known invocation boundaries is the primary runtime containment mechanism.
- `OnError` is a last-resort reporter, not the normal control-flow mechanism.
- Load-time errors are prevented through validation before launch or reload; they cannot be recovered with runtime `try/catch`.
- Logs must be bounded, local, useful for diagnosis, and redact sensitive values by default.
- Automatic restart must be bounded and must never create an unlimited crash loop.
- Existing user-visible behavior should remain unchanged unless this plan explicitly changes it.
- The implementation should use native AutoHotkey capabilities and existing project utilities where practical.

## Target Architecture

```text
Startup supervisor
    |
    +-- validate all enabled entrypoints before changing running services
    |
    +-- launch and monitor service processes
    |       +-- service identity, PID, status, restart policy
    |       +-- ready/failed signal and optional heartbeat
    |
    +-- expose suite status and diagnostics in the tray

Each service process
    |
    +-- minimal base dependencies
    +-- ErrorReporter + OnError fallback
    +-- SafeCall boundaries
            +-- actions
            +-- hotkeys and gestures
            +-- timers and clipboard callbacks
            +-- GUI events
            +-- initialization steps
```

## Error Categories and Required Behavior

### Expected outcome

Examples: cancelled confirmation, unavailable application, optional feature disabled, or validation of user input.

Required behavior: return a structured non-error result. Do not log it as a failure and do not display an error dialog.

### Recoverable invocation failure

Examples: a Spotify UI element is temporarily missing, a window closes during automation, or an individual action throws.

Required behavior: end only that invocation, log the diagnostic, return a structured failure, and keep the owning service available.

### Unhandled runtime failure

Examples: a hotkey, timer, GUI event, or callback throws outside its normal safe boundary.

Required behavior: the global error handler records and reports it, suppresses the default blocking dialog, and lets AutoHotkey end the failed thread. It must not force execution to continue from an unknown state.

### Load-time or critical failure

Examples: syntax error, missing required include, invalid class initialization, or an error that terminates the process.

Required behavior: preflight validation prevents known load failures from replacing working services. If a process still terminates, the supervisor marks only that service failed and applies its bounded restart policy.

### Supervisor failure

Required behavior: already-running child services should remain functional where the operating system permits it. The supervisor must not kill all AutoHotkey processes as part of ordinary recovery.

## Phase 1 — Inventory and Baseline

- [ ] Create one inventory of every production entrypoint launched directly or indirectly by `Startup/Startup.ahk`.
- [ ] Assign each entrypoint a stable service ID, human-readable name, category, criticality, profile rules, and owner script.
- [ ] Record which entrypoints are persistent and which are expected to exit after completing one task.
- [ ] Record the current `#Requires`, `#SingleInstance`, `#NoTrayIcon`, and persistence behavior for every entrypoint.
- [ ] Catalogue all production uses of `MsgBox`, separating confirmations, ordinary information, expected validation feedback, and error reporting.
- [ ] Catalogue all explicit `throw` sites in first-party production code and document which caller is expected to catch each one.
- [ ] Catalogue all hotkey, hotstring, timer, GUI, clipboard, menu, message, and gesture callback registration sites.
- [ ] Catalogue all startup-time static class initialization and other auto-execute work that can fail before a service becomes ready.
- [ ] Identify dependency cycles and broad include chains rooted at `Lib/Core.ahk`.
- [ ] Document a reproducible baseline for starting, reloading, switching profiles, and exiting the complete suite.
- [ ] Record the current behavior for at least one representative failure in each error category before changing it.

## Phase 2 — Entrypoint Contract and Service Manifest

- [ ] Define a service manifest model with service ID, display name, script path, enabled/profile predicate, criticality, startup timeout, restart policy, and health policy.
- [ ] Move the startup script list from repeated bare `Run()` calls into one authoritative service manifest.
- [ ] Define whether each service is `critical`, `standard`, or `optional`, and document what that classification changes.
- [ ] Add `#Requires AutoHotkey v2` to every first-party production entrypoint.
- [ ] Make every persistent entrypoint explicitly declare its `#SingleInstance` behavior instead of inheriting it from `Lib/Core.ahk`.
- [ ] Make every entrypoint explicitly declare whether it owns a tray icon instead of inheriting `#NoTrayIcon` from a shared include.
- [ ] Give each launched process access to its stable service ID, either through an argument or a small service runtime bootstrap.
- [ ] Ensure paths passed to AutoHotkey are quoted safely and do not rely on the caller's working directory.
- [ ] Capture and retain the PID returned when each service is launched.
- [ ] Prevent two manifest entries from using the same service ID or unintentionally targeting the same single-instance script.
- [ ] Add manifest validation for missing files, invalid categories, invalid restart settings, and contradictory profile rules.

## Phase 3 — Preflight Validation and Safe Reload

- [ ] Add a validator that invokes AutoHotkey with `/Validate /ErrorStdOut` for one entrypoint and returns a structured validation result.
- [ ] Validate with the same AutoHotkey v2 interpreter that production launch will use.
- [ ] Preserve the full validation diagnostic including script, included file, line, message, and exit code.
- [ ] Add a command that validates every enabled manifest entry without executing its auto-execute section.
- [ ] Ensure one failed validation does not prevent the remaining entries from being checked and reported.
- [ ] Add a concise validation summary suitable for the startup tray and a detailed diagnostic suitable for logs.
- [ ] Change suite startup so each service is validated before it is launched.
- [ ] Define and implement two-phase suite reload: validate every enabled service first, and change no running services if validation fails.
- [ ] Define and implement per-service reload: validate the target first and leave its current process running if validation fails.
- [ ] Ensure profile switching validates the target profile's enabled services before replacing the current set.
- [ ] Add a development command that validates all production entrypoints and returns a non-zero exit status when any fail.
- [ ] Document how the validation command can be used manually and by a future continuous-integration workflow.

## Phase 4 — Error Record and Error Reporter

- [ ] Define an immutable or safely constructed `ErrorRecord` model.
- [ ] Include timestamp, severity, category, service ID, operation ID, user-safe message, error type, error message, `What`, file, line, stack, mode, duration, and fingerprint where available.
- [ ] Define severity values and their meaning, including at least `warning`, `error`, and `critical`.
- [ ] Define stable error categories that distinguish validation, initialization, invocation, callback, dependency, process-exit, and supervisor failures.
- [ ] Implement `ErrorReporter.Report()` as the single first-party path for recording unexpected failures.
- [ ] Make the reporter safe to call when optional UI dependencies have not loaded.
- [ ] Make reporter failures non-recursive: failure to log or notify must not trigger another reporting loop.
- [ ] Store logs outside the repository by default, under a stable local application-data directory.
- [ ] Use a deterministic, machine-readable log format such as JSON Lines, with a human-readable fallback if JSON serialization fails.
- [ ] Bound log growth through rotation or size/count retention limits.
- [ ] Flush each important error record promptly enough that a terminating process does not normally lose it.
- [ ] Redact secrets, clipboard contents, action arguments, URLs with sensitive query values, and credentials by default.
- [ ] Add a deliberate opt-in development mode for richer diagnostics without weakening production redaction.
- [ ] Add an error fingerprint that permits identical repeated failures to be grouped.
- [ ] Rate-limit or coalesce notifications for repeated fingerprints while continuing to record useful occurrence counts.
- [ ] Provide a user-safe summary separately from the developer diagnostic.
- [ ] Add a diagnostic action or tray item to open the log directory.
- [ ] Add a diagnostic action or tray item to copy the latest sanitized error summary.

## Phase 5 — Non-Blocking User Notification

- [ ] Define one notification interface independent of the existing `Info` GUI implementation.
- [ ] Provide a minimal fallback based on a native tray notification when the preferred notification UI cannot load.
- [ ] Show service name, failed operation, and a short recovery hint without exposing a stack trace or secret data.
- [ ] Ensure error notifications auto-close and never require the user to dismiss them before unrelated hotkeys work.
- [ ] Keep destructive and sensitive confirmations separate from error notifications.
- [ ] Replace first-party error-reporting `MsgBox` calls with the reporter/notification path.
- [ ] Keep deliberate development/demo `MsgBox` calls out of production execution paths or guard them behind development mode.
- [ ] Make repeated notifications collapse into a count such as “failed 8 times” rather than opening eight windows.
- [ ] Add a tray-visible indication when one or more services are degraded, even after transient notifications disappear.

## Phase 6 — Safe Invocation Boundaries

- [ ] Define `SafeCall(operationId, callback, context?, args*)` or an equivalent API with documented semantics.
- [ ] Require a stable operation ID so failures can be traced and deduplicated without depending on user-facing labels.
- [ ] Make `SafeCall` catch `Error` and other values that AutoHotkey permits code to throw.
- [ ] Convert caught failures into a structured result instead of returning an ambiguous empty string or bare `false`.
- [ ] Record duration and service context for every failed safe invocation.
- [ ] Ensure expected cancellations and unavailable outcomes bypass error reporting.
- [ ] Ensure `SafeCall` never silently swallows an unexpected failure without producing a log record.
- [ ] Define an optional fallback value only for callers that can safely continue with that value.
- [ ] Add adapters for hotkey and hotstring callbacks.
- [ ] Add adapters for `SetTimer` callbacks.
- [ ] Add adapters for GUI and control `OnEvent` callbacks.
- [ ] Add adapters for clipboard callbacks.
- [ ] Add adapters for menu callbacks.
- [ ] Add adapters for mouse gesture callbacks.
- [ ] Add adapters for other asynchronous callbacks used by the production suite.
- [ ] Migrate first-party callback registrations to the adapters, prioritizing high-frequency and high-impact callbacks.
- [ ] Verify that an exception in each migrated callback type ends only that invocation and does not disable later invocations.

## Phase 7 — Action Registry Integration

- [ ] Preserve `ActionResult` as the authoritative result returned by `ActionRegistry.Invoke()`.
- [ ] Define exactly which `ActionResult` statuses are expected outcomes and which require error reporting.
- [ ] Route `ActionRegistry.Invoke()` execution exceptions through `ErrorReporter` before returning `execution-failed`.
- [ ] Add service ID, action ID, consumer, profile, active-window metadata, and duration to the action failure record where safely available.
- [ ] Keep raw arguments and clipboard-derived values out of action logs by default.
- [ ] Ensure availability-check and state-getter failures can be diagnosed instead of being silently reduced to `false`.
- [ ] Prevent confirmation cancellation from being recorded as an error.
- [ ] Ensure every action consumer handles structured failure results without opening an error `MsgBox`.
- [ ] Add one shared consumer policy for whether failures are shown immediately, shown only in service status, or logged silently.
- [ ] Update action-registry documentation with failure semantics and examples.
- [ ] Coordinate this phase with `plan.md` so the action migration does not introduce a second competing error abstraction.

## Phase 8 — Global `OnError` Fallback

- [ ] Register one global `OnError` callback from the minimal service bootstrap before optional components initialize.
- [ ] Convert the received thrown value and error mode into an `ErrorRecord` without assuming it is always an `Error` object.
- [ ] Return the value that suppresses AutoHotkey's normal blocking error dialog after reporting succeeds or safely fails.
- [ ] Do not use the continuation return value for arbitrary runtime errors.
- [ ] Allow AutoHotkey to terminate the failed event thread when continuation is unsafe.
- [ ] Handle critical error modes without pretending that the process can recover.
- [ ] Keep the `OnError` callback short, non-blocking, and protected against its own failures.
- [ ] Ensure `OnError` does not display `MsgBox`, perform slow network work, or depend on WebView/UIA.
- [ ] Add an `OnExit` callback that reports unexpected process termination when it is safe to do so.
- [ ] Distinguish intentional exit, reload, profile change, single-instance replacement, shutdown, and unexpected failure.
- [ ] Verify that errors already caught by `SafeCall` or `ActionRegistry` are not double-reported by `OnError`.

## Phase 9 — Service Readiness, Health, and Supervision

- [ ] Implement a small service-runtime bootstrap that reports `starting`, `ready`, `degraded`, `stopping`, and `failed` states.
- [ ] Define a lightweight local communication mechanism for status that does not require a network service.
- [ ] Remove stale status belonging to PIDs that no longer exist.
- [ ] Require persistent services to report `ready` only after their essential initialization succeeds.
- [ ] Define a startup timeout per service and mark a service failed if it exits or never becomes ready in time.
- [ ] Monitor tracked PIDs without accidentally matching unrelated AutoHotkey processes.
- [ ] Define whether each service needs only process-liveness monitoring or also a heartbeat.
- [ ] Add heartbeats only where a hung-but-running service would materially affect the suite.
- [ ] Define restart defaults with bounded attempts, increasing delay, and a time window.
- [ ] Implement restart attempts per service without restarting healthy siblings.
- [ ] Stop restarting and quarantine a service after its retry budget is exhausted.
- [ ] Reset the restart budget after a service has remained healthy for the configured stability period.
- [ ] Never automatically restart services intentionally stopped by the user, profile rules, suite exit, or profile transition.
- [ ] Ensure optional-service failure never makes the complete suite report total startup failure.
- [ ] Define the minimum critical services required for the suite to report healthy.
- [ ] Add manual `Start`, `Stop`, `Restart`, and `Validate` operations for an individual service.
- [ ] Add `Restart failed services` without touching healthy services.
- [ ] Prevent ordinary recovery from calling `KillAllAHkProcesses()`.
- [ ] Reserve forced process termination for a confirmed user operation or a timed-out graceful shutdown of a precisely identified PID.

## Phase 10 — Startup Tray and Diagnostics

- [ ] Replace the current static startup tray construction with status generated from the service manifest.
- [ ] Display an overall suite state of at least `starting`, `healthy`, `degraded`, and `failed`.
- [ ] Display every enabled service and its current state.
- [ ] Show disabled-by-profile services distinctly from failed services.
- [ ] Provide per-service validation and restart commands.
- [ ] Provide a full-suite validation command.
- [ ] Provide a safe full-suite reload that uses the two-phase validation rule.
- [ ] Show the latest sanitized failure for a failed or degraded service.
- [ ] Provide access to logs and a copyable diagnostic summary.
- [ ] Keep profile switching available when an optional service is failed.
- [ ] Keep suite exit explicit and separate from service recovery.
- [ ] Ensure tray callback failures themselves use a safe invocation boundary.

## Phase 11 — Reduce the `Core.ahk` Failure Radius

- [ ] Define a minimal base module containing only stable process-wide setup, paths, service context, and error infrastructure.
- [ ] Remove application adapters, WebView, UIA, desktop integration, and unrelated helpers from the minimal base.
- [ ] Split the remaining shared imports into cohesive modules such as profile, UI, web, automation, and application adapters.
- [ ] Move process directives out of shared libraries and into entrypoints.
- [ ] Replace broad `#Include Lib/Core.ahk` usage with the narrowest practical module imports.
- [ ] Remove or resolve circular includes between Core, profiles, secrets, helpers, and application adapters.
- [ ] Prevent optional integrations from performing failure-prone static initialization merely because their file was included.
- [ ] Prefer explicit `Initialize()` calls for components that touch files, COM, WebView, UIA, DLLs, or external applications.
- [ ] Make optional component initialization return a structured result or throw into a documented safe initialization boundary.
- [ ] Ensure failure of an optional integration does not prevent unrelated hotkeys in the same service from registering when separation is practical.
- [ ] Re-run the entrypoint dependency inventory after the split and document the reduced include graph.
- [ ] Remove the old broad Core compatibility layer only after every production consumer has migrated.

## Phase 12 — Startup and Initialization Boundaries

- [ ] Divide each service's initialization into named essential and optional steps.
- [ ] Wrap each optional initialization step independently and mark the service degraded when it fails.
- [ ] Fail the service startup when an essential initialization step fails.
- [ ] Record which initialization step failed and whether it was essential.
- [ ] Avoid showing startup success until all essential steps are complete.
- [ ] Replace the unconditional startup success message with a state-aware healthy/degraded summary.
- [ ] Ensure a failed child service does not prevent the supervisor tray from becoming available.
- [ ] Ensure one failed `Run()` call does not abort launching the remaining valid services.
- [ ] Ensure missing optional assets produce a degraded feature rather than an unrelated suite-wide failure.
- [ ] Ensure profile and secrets initialization produce sanitized diagnostics that do not expose secret values.

## Phase 13 — Migration of Existing Error Paths

- [ ] Replace production error `MsgBox` calls in profiles and startup with structured reporting.
- [ ] Replace production error `MsgBox` calls in integrated apps with expected results or structured reporting as appropriate.
- [ ] Replace production error `MsgBox` calls in standalone apps with expected results or structured reporting as appropriate.
- [ ] Review every empty `catch` and either document why failure is intentionally ignored or report/return it appropriately.
- [ ] Review every `try` without `catch` and confirm that silent failure is safe and intentional.
- [ ] Review every `ExitApp` and classify it as intentional lifecycle behavior or an error-recovery shortcut.
- [ ] Remove `ExitApp` from recoverable feature failures.
- [ ] Review `Reload()` calls used “to prevent errors” and replace them with precise cleanup or recovery where practical.
- [ ] Standardize user-facing wording for unavailable, validation-failed, execution-failed, and service-failed outcomes.
- [ ] Preserve confirmations for destructive operations, including killing AHK processes and system shutdown actions.
- [ ] Add a short code comment at intentionally swallowed best-effort cleanup failures.

## Phase 14 — Automated and Manual Verification

- [ ] Add tests for error-record construction from an `Error` object and from a non-`Error` thrown value.
- [ ] Add tests for redaction of secrets, arguments, clipboard-derived text, and sensitive URLs.
- [ ] Add tests for log rotation and retention.
- [ ] Add tests for repeated-error notification coalescing.
- [ ] Add tests for `SafeCall` success, expected outcome, thrown error, fallback value, and reporter failure.
- [ ] Add tests for every `ActionResult` failure classification.
- [ ] Add tests that availability-check and state-getter failures produce diagnostics.
- [ ] Add manifest validation tests for duplicate IDs, missing scripts, invalid policy values, and profile filtering.
- [ ] Add validator tests using one intentionally valid fixture and representative invalid fixtures.
- [ ] Add supervisor tests for normal exit, unexpected exit, startup timeout, bounded restart, quarantine, and manual restart.
- [ ] Add tests that intentional stop, reload, profile switch, and suite exit do not consume restart attempts.
- [ ] Add tests that a failed optional service leaves the overall suite degraded rather than failed.
- [ ] Add tests that a critical-service failure produces the defined overall state.
- [ ] Add a production-entrypoint validation test that runs across the complete manifest.
- [ ] Manually trigger an action exception and verify later actions in the same service still work.
- [ ] Manually trigger failures in a hotkey, timer, GUI event, clipboard callback, gesture, and tray callback.
- [ ] Manually introduce a syntax error in a test fixture and verify validation reports it without a blocking dialog.
- [ ] Manually simulate a missing include and verify the current working service is not replaced during reload.
- [ ] Manually simulate a service crash and verify only that service restarts.
- [ ] Manually simulate a repeated crash and verify restart quarantine occurs without a dialog storm.
- [ ] Manually verify logs and copied diagnostics contain no known secret or raw sensitive input.
- [ ] Manually verify healthy hotkeys remain responsive while another service reports an error.
- [ ] Manually verify suite exit and profile switching still work in healthy and degraded states.

## Phase 15 — Rollout and Documentation

- [ ] Introduce the infrastructure behind a temporary development flag before enabling dialog suppression globally.
- [ ] Run the suite in development mode long enough to identify callbacks that bypass safe boundaries.
- [ ] Migrate services incrementally and record completion in the service inventory.
- [ ] Enable global non-blocking production reporting only after logs and fallback notification have been verified.
- [ ] Enable supervisor restarts only after intentional exits are correctly distinguished.
- [ ] Document log location, retention, redaction, service states, restart behavior, and diagnostic commands.
- [ ] Document how to add a new service to the manifest.
- [ ] Document how to register a new callback through a safe adapter.
- [ ] Document how actions should return expected failures versus throw unexpected failures.
- [ ] Document how developers can temporarily enable detailed diagnostics safely.
- [ ] Update installation instructions with any required startup or interpreter changes.
- [ ] Remove the temporary rollout flag after all production services satisfy the entrypoint contract.
- [ ] Perform the final acceptance run on every supported profile/device category.

## Acceptance Specifications

### SPEC-01 — Failure isolation

When an action or asynchronous callback throws a recoverable error, only that invocation ends. Later invocations and unrelated services remain functional.

### SPEC-02 — No blocking production error dialogs

Unexpected production errors do not open AutoHotkey's standard error dialog or a custom error `MsgBox`. Explicit confirmations may still use a modal dialog.

### SPEC-03 — No unsafe continuation

The global error handler never asks AutoHotkey to continue arbitrary code after an unhandled runtime error. It reports the error and allows the failed thread or process to end according to AutoHotkey semantics.

### SPEC-04 — Load errors are caught before replacement

Every enabled production entrypoint passes `/Validate /ErrorStdOut` before initial launch, reload, or profile transition. A validation failure leaves the currently running valid services unchanged.

### SPEC-05 — Complete entrypoint contract

Every production entrypoint explicitly declares AutoHotkey v2, single-instance behavior, tray behavior, and service identity.

### SPEC-06 — Action result integrity

Every `ActionRegistry.Invoke()` call returns a documented `ActionResult`. Cancellation, unavailability, validation failure, and execution failure remain distinguishable.

### SPEC-07 — Observable failures

Every unexpected first-party failure at a supported boundary creates one sanitized diagnostic record or an explicit fallback indication that recording failed. Unexpected errors are never silently swallowed.

### SPEC-08 — Sensitive-data protection

Production logs and notifications do not contain secret values, credentials, raw clipboard contents, or raw action arguments unless a narrowly scoped development option was deliberately enabled.

### SPEC-09 — Bounded storage

Error logs cannot grow without limit. Rotation and retention behavior is documented and automatically enforced.

### SPEC-10 — Notification resilience

Error notifications are non-modal, auto-closing, and rate-limited. Failure of the preferred notification UI falls back safely and does not recursively generate errors.

### SPEC-11 — Service-level status

The supervisor can distinguish disabled, starting, ready, degraded, stopped, failed, restarting, and quarantined services without relying on unrelated AutoHotkey process names.

### SPEC-12 — Bounded restart

Unexpected process exit restarts only the affected service, within its configured retry budget. Exhausting the budget quarantines that service and does not create an infinite loop.

### SPEC-13 — Intentional lifecycle behavior

Manual stop, suite exit, profile switching, reload, shutdown, and single-instance replacement are not misclassified as crashes and do not trigger unwanted restarts.

### SPEC-14 — Partial availability

Failure of an optional service reports an overall degraded state while all healthy services continue operating. Failure of a critical service produces the explicitly defined suite failure state.

### SPEC-15 — Precise process control

Normal supervision targets exact tracked service PIDs. It never kills all AutoHotkey processes as an automatic recovery technique.

### SPEC-16 — Reduced Core coupling

Production entrypoints include only the shared modules they require. Breaking an optional UIA, WebView, application-adapter, or desktop-integration module does not prevent unrelated services from validating.

### SPEC-17 — Safe initialization

Services report ready only after essential initialization succeeds. Optional initialization failures create a degraded service with a named diagnostic rather than false startup success.

### SPEC-18 — Diagnostic usefulness

A developer can identify the failed service, operation, source file, line, error type, stack where available, occurrence count, and timestamp without reproducing the failure immediately.

### SPEC-19 — Reporter independence

Error reporting remains operational when optional project UI, WebView, UIA, internet, external applications, profile persistence, or application adapters are unavailable.

### SPEC-20 — Full-suite regression safety

Startup, ordinary hotkeys, dashboards, profile switching, per-service restart, full reload, and suite exit continue to work on every supported profile after the migration.

## Definition of Done

- [ ] Every task in this document is checked or explicitly removed through a reviewed scope decision.
- [ ] Every acceptance specification has a recorded passing verification result.
- [ ] Every enabled production entrypoint passes automated validation.
- [ ] Every production callback category has a verified safe error boundary.
- [ ] All first-party production error `MsgBox` paths have been removed or reclassified as explicit confirmations.
- [ ] Logs are bounded, sanitized, readable, and reachable from the suite diagnostics UI.
- [ ] Service restart and quarantine behavior has been demonstrated with controlled failures.
- [ ] A broken optional service has been demonstrated not to interrupt unrelated functionality.
- [ ] A load-time failure has been demonstrated not to replace the currently working suite.
- [ ] Documentation describes the architecture and the rules for future services, actions, and callbacks.
- [ ] The implementation has completed a stable real-world observation period without blocking error dialogs or uncontrolled restart loops.

## Deferred Ideas

The following are intentionally not required for completion unless later promoted into scope:

- Sending diagnostics to a remote server.
- A WebView-based historical error dashboard.
- Automatic source rollback or Git checkout.
- Compiling every service to an executable.
- Running every individual action in its own process.
- Automatic repair of broken scripts using generated code.

