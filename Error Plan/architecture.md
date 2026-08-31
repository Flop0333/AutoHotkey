# Error Resilience Architecture

```text
Startup Supervisor
├─ ServiceManifest
├─ EntrypointValidator
├─ ServiceLauncher (captures PID)
├─ ServiceMonitor
├─ RestartPolicy
└─ Status-driven tray

Each service process
├─ MinimalServiceBootstrap
│  ├─ ServiceContext
│  ├─ ErrorReporter
│  ├─ OnError fallback
│  └─ OnExit lifecycle reporting
├─ Essential/optional initialization steps
└─ SafeCall callback adapters
```

## Error behavior

| Category | Behavior |
|---|---|
| Expected outcome | Structured result; no error log or error notice |
| Recoverable invocation | End invocation, report, return failure, keep service alive |
| Unhandled runtime | Global fallback reports; failed thread/process ends safely |
| Load/critical | Preflight blocks replacement; supervisor isolates process failure |
| Supervisor failure | Existing child processes continue where Windows permits |

## Core models

### ServiceDefinition

Stable ID, name, path, profile predicate, category, criticality, persistence, startup timeout, restart policy, and health policy.

### OperationResult

Statuses: `success`, `cancelled`, `unavailable`, `validation-failed`, and `execution-failed`. Expected non-success outcomes are not unexpected errors.

### ErrorRecord

Immutable diagnostic and user-safe fields defined by `REQ-ERR-002`. Construction supports AHK `Error` and arbitrary thrown values.

### ServiceStatus

Service ID, PID, state, timestamp, essential initialization progress, last sanitized failure, and optional heartbeat.

## Dependency rules

- Minimal base must not include WebView, UIA, virtual desktops, app adapters, or internet dependencies.
- Reporter dependencies must be stable and have fallbacks.
- Supervisor depends on manifest/runtime contracts, never individual service internals.
- Services write status; supervisor reads it. Children do not require the supervisor to remain alive.
- Process control always targets captured and verified PIDs.

