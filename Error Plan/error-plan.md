# Error Resilience Project

## Goal

Make the AutoHotkey suite resilient so one broken operation, callback, include, initialization step, or service does not unnecessarily interrupt unrelated functionality.

The system must prevent load failures before replacing working processes, contain runtime failures at known boundaries, report unexpected errors without blocking dialogs or sensitive data leakage, and supervise each AHK service independently with bounded recovery.

## Authoritative files

All material for this project stays in `Error Plan/`:

1. [AGENTS.md](AGENTS.md) — Copilot execution rules.
2. [requirements.md](requirements.md) — stable requirement IDs.
3. [architecture.md](architecture.md) — runtime design and boundaries.
4. [decisions.md](decisions.md) — resolved version 1 choices.
5. [test-plan.md](test-plan.md) — automated and manual verification.
6. [service-inventory.md](service-inventory.md) — production entrypoints, baseline, and source audits.
7. [tasks.md](tasks.md) — authoritative execution state.
8. [verification.md](verification.md) — requirement evidence and phase approvals.

## Implementation workflow

When asked to implement the error plan, Copilot implements exactly the first eligible `READY` task in `tasks.md`, records evidence, prepares the next task, and stops. Phase gates require human approval.

## Target design

```text
Startup Supervisor
├─ validates every enabled entrypoint before replacement
├─ launches services from one manifest and captures exact PIDs
├─ reads service readiness/health
├─ applies bounded per-service restart policy
└─ generates status and diagnostics tray UI

Each service
├─ explicit entrypoint directives and service identity
├─ minimal error/bootstrap dependencies
├─ essential and optional initialization steps
├─ SafeCall callback boundaries
├─ OnError last-resort reporting
└─ OnExit lifecycle classification
```

## Required behavior

### Expected outcomes

Cancellation, validation feedback, unavailable optional dependencies, and disabled features return structured outcomes. They are not unexpected errors.

### Recoverable invocation failures

Only the current invocation ends. It produces a sanitized diagnostic and structured failure; later invocations and sibling services remain available.

### Unhandled runtime failures

The global fallback records and reports the failure, suppresses AHK's blocking dialog, and never requests unsafe continuation. AHK ends the failed thread/process according to its semantics.

### Load and critical failures

Preflight validation blocks invalid launch/reload/profile transition from replacing current working services. Unexpected process death affects and potentially restarts only that service.

### Supervisor failure

Already-running child services remain functional where Windows permits. Ordinary recovery never kills every AHK process.

## Version 1 scope

- Production entrypoints launched by `Startup/Startup.ahk`.
- Manifest, validation, safe reload, and profile transition.
- Error model, redaction, bounded local logs, non-modal notification.
- Safe boundaries for every first-party callback category.
- Minimal `OnError`/`OnExit` bootstrap.
- Service readiness, status, exact-PID supervision, bounded restart, and quarantine.
- Status-driven startup tray and diagnostics.
- Reduced `Core.ahk` failure radius and explicit initialization.
- Migration of first-party production error paths.
- Automated and controlled manual failure verification.

Third-party examples, remote diagnostics, automatic code repair/rollback, compiled services, and per-action processes are deferred.

## Non-negotiable invariants

- AutoHotkey v2 only.
- No blocking production error dialogs; confirmations may remain modal.
- No unsafe continuation after unhandled runtime errors.
- No secret, credential, raw clipboard, raw argument, or sensitive URL leakage.
- No unbounded log growth or restart loop.
- No automatic `KillAllAHkProcesses()` recovery.
- No process-name-only control when a tracked PID is available.
- No dependency on the removed Action Registry.
- No dependency on the Personal Agent project.
- Existing behavior remains unless a requirement explicitly changes it.

## Definition of done

Version 1 is finished only when:

- [ ] TASK-ERR-001 through TASK-ERR-029 are `DONE`.
- [ ] All five phase gates are human-approved and `DONE`.
- [ ] Every requirement ID has passing evidence in `verification.md`.
- [ ] Every enabled production entrypoint validates automatically.
- [ ] Every production callback category has a verified safe boundary.
- [ ] All first-party production error `MsgBox` paths are removed or classified as explicit confirmations.
- [ ] Error records are bounded, sanitized, useful, and available from diagnostics.
- [ ] Default AHK blocking error dialogs are suppressed through the safe fallback.
- [ ] A load-time failure has been demonstrated not to replace working services.
- [ ] A callback failure has been demonstrated not to disable later invocations.
- [ ] An optional service failure has been demonstrated not to interrupt healthy services.
- [ ] A process crash restarts only its service and repeated crashes quarantine it.
- [ ] Intentional stop/reload/profile/exit operations do not trigger restart.
- [ ] Minimal reporter/bootstrap works without optional WebView, UIA, internet, or app adapters.
- [ ] Startup, hotkeys, dashboards, profile switching, recovery, reload, and exit regressions pass on supported profiles.
- [ ] Documentation covers logs, states, restart, new services, safe callbacks, and expected-vs-unexpected failures.
- [ ] A stable observation period records no blocking error dialogs or uncontrolled restart loops.

## Normal Copilot instruction

> Implement the error resilience feature.

`AGENTS.md` and `tasks.md` determine the next task, scope, verification, and stopping point.

