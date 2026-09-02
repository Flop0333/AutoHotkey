# Local Logging and Diagnostics Dashboard Plan

## Purpose

Build a reliable local observability system for the AutoHotkey suite. It must record useful errors, warnings, lifecycle events, and selected successful operations; show the current suite run in a responsive dashboard; retain bounded history; and remain safe when the dashboard, storage, or logging code fails.

This document is the implementation contract for spec-driven, AI-assisted development. An implementation is complete only when every requirement and acceptance statement has verified evidence.

## Goals

- Give the user one place to understand whether the suite and its services are healthy.
- Show live events from the current suite run by default.
- Make previous runs available for a bounded retention period.
- Preserve enough structured context to diagnose failures without exposing secrets.
- Support `debug`, `info`, `warning`, `error`, and `critical` events.
- Represent success as an event outcome rather than inventing a `success` severity.
- Group repeated failures by fingerprint and prevent notification storms.
- Work across the independent AHK processes launched by `Startup/Startup.ahk`.
- Keep logging operational when the dashboard is closed or broken.
- Keep the dashboard operational when one log file is incomplete or malformed.

## Non-goals for version 1

- Azure Application Insights or any remote telemetry service.
- Network transmission, cloud synchronization, or multi-device aggregation.
- A database server or Windows service.
- Full distributed tracing.
- Recording every hotkey invocation or every successful low-value operation.
- Automatically repairing application failures.
- Using the repository as the production log store.
- Making WebView, UIA, internet access, or the dashboard a logging dependency.

## Locked architecture decisions

These decisions are considered accepted unless the user explicitly revises them.

1. Production logs live under `%LOCALAPPDATA%\AutoHotkey Workflow\Logs`, not inside the repository.
2. The storage format is UTF-8 JSON Lines (`.jsonl`), with exactly one complete JSON object per physical line.
3. One Startup invocation creates one `suiteRunId`. All child processes launched by that Startup invocation inherit it.
4. Each AHK process writes to its own file. Multiple processes never append to one shared primary file.
5. An independently launched standalone application creates its own suite run when no inherited run ID exists.
6. The dashboard defaults to the current suite run and can select retained historical runs.
7. Disk files are the source of truth. The dashboard is a reader, never a required logging sink.
8. Version 1 live updates use incremental polling every 750 ms. Named pipes, sockets, and other IPC are deferred.
9. The first dashboard implementation uses native AHK v2 GUI controls. A future WebView frontend may reuse the reader/model contracts.
10. Retention is bounded by both age and total size: 14 days and 100 MiB by default.
11. Cleanup occurs at startup and on explicit user request, never in the critical path of every log write.
12. The active run is never deleted by automatic retention.
13. Errors are always logged where possible. Info and success logging is selective. Debug logging is disabled by default.
14. Notifications and persistence are independent policies. A persisted event does not necessarily notify the user.
15. The dashboard is opened on demand from the Startup tray menu. It does not need to remain open for logging.
16. Existing `ErrorReporter` callers remain compatible during migration.

## System overview

```text
Startup.ahk
├── creates SuiteRunContext
├── writes suite.started
├── launches child processes with inherited suiteRunId
└── exposes "Diagnostics" in tray menu

Each AHK process
├── creates ProcessRunContext
├── writes only to its own JSONL file
├── Logger normalizes, redacts, serializes, and appends events
├── ErrorReporter adapts existing error calls to Logger
└── NotificationPolicy optionally emits a sanitized TrayTip

Diagnostics Dashboard
├── discovers retained suite runs
├── incrementally tails all process files in selected run
├── validates and merges events by timestamp and sequence
├── groups repeated fingerprints
└── displays overview, live events, history, and details
```

## Storage layout

```text
%LOCALAPPDATA%\AutoHotkey Workflow\Logs\
├── runs\
│   ├── 2026-09-02\
│   │   ├── run-20260902T081530-4F8A\
│   │   │   ├── run.json
│   │   │   ├── startup-4932.jsonl
│   │   │   ├── window_manager-6104.jsonl
│   │   │   └── desktops_manager-7220.jsonl
│   │   └── run-20260902T174020-91C2\
│   │       └── ...
│   └── ...
└── fallback\
    └── reporter-fallback.jsonl
```

### Path rules

- `suiteRunId` format: `run-YYYYMMDDTHHMMSS-XXXX`, where `XXXX` is a random hexadecimal suffix.
- Process filename format: `<sanitized-service-id>-<pid>.jsonl`.
- Service IDs in paths may contain only lowercase ASCII letters, digits, `_`, and `-`; other characters become `_`.
- A process opens or appends only its own process file.
- `run.json` is descriptive metadata, not the source of event truth. A missing or incomplete manifest must not hide process logs.
- The logger must create missing directories safely and fall back without throwing to its caller.
- No raw secrets, clipboard contents, command arguments, or sensitive URLs may appear in directory or file names.

## Run identity and lifecycle

### Suite run

A suite run represents the lifetime of one `Startup.ahk` invocation and the processes it launches.

Required fields:

- `suiteRunId`
- `startedAt`
- `startupPid`
- `profileId`, sanitized
- `computerId`, non-sensitive or hashed if needed
- `schemaVersion`
- optional `endedAt`
- optional `exitReason`

Startup places the run ID in `AHK_SUITE_RUN_ID` before launching children. Child processes read but do not rewrite that variable. If the variable is absent or invalid, a process creates a new suite run identity.

### Process run

A process run represents one OS process lifetime.

Required fields on all events:

- `processRunId`, formatted `<serviceId>-<pid>-<suffix>`
- `processId`
- `serviceId`
- `suiteRunId`

Expected lifecycle events:

- `process.starting`
- `process.ready`
- `process.degraded`
- `process.stopping`
- `process.exited`
- `process.failed`

Intentional reloads, profile transitions, explicit exits, Windows shutdown, and unexpected exits must remain distinguishable.

## Canonical event schema

Every event uses schema version `1` and contains these fields unless marked optional.

| Field | Type | Required | Meaning |
|---|---|---:|---|
| `schemaVersion` | integer | yes | Event contract version; initially `1` |
| `eventId` | string | yes | Unique ID within all local logs |
| `sequence` | integer | yes | Monotonically increasing within one process run |
| `timestamp` | string | yes | Local ISO-8601 timestamp with milliseconds and UTC offset |
| `level` | string | yes | `debug`, `info`, `warning`, `error`, or `critical` |
| `eventType` | string | yes | Stable machine-readable name such as `operation.failed` |
| `outcome` | string | no | `success`, `cancelled`, `unavailable`, `validation-failed`, or `execution-failed` |
| `suiteRunId` | string | yes | Correlates processes launched by one Startup run |
| `processRunId` | string | yes | Correlates one process lifetime |
| `processId` | integer | yes | OS PID |
| `serviceId` | string | yes | Stable service identity |
| `operationId` | string | no | Stable operation identity |
| `category` | string | yes | Event category |
| `message` | string | yes | Sanitized, user-readable summary |
| `durationMs` | integer | no | Completed operation duration |
| `fingerprint` | string | no | Stable grouping identity for equivalent failures |
| `occurrence` | integer | no | Local aggregated occurrence count when applicable |
| `error` | object | no | Sanitized structured failure details |
| `properties` | object | no | Allowlisted structured metadata only |

### Error object

When present, `error` may contain:

- `type`
- `message`
- `what`
- `file`
- `line`
- `stack`

All values must be redacted before serialization. The raw thrown value must never be retained after normalization.

### Categories

Version 1 categories are:

- `lifecycle`
- `initialization`
- `operation`
- `callback`
- `validation`
- `dependency`
- `configuration`
- `io`
- `notification`
- `process`
- `supervisor`
- `reporter`
- `dashboard`

New categories require documentation and tests; callers must not create arbitrary spelling variants.

### Event type naming

- Use lowercase dot-separated names.
- Use a stable noun followed by a state or action: `suite.started`, `operation.completed`, `operation.failed`.
- Do not encode dynamic values in event types.
- Put dynamic context in allowlisted properties.

## Public logging API

The target API is conceptually:

```ahk
Logger.Debug(eventType, message, context?)
Logger.Info(eventType, message, context?)
Logger.Warning(eventType, message, context?)
Logger.Error(eventType, thrownOrMessage, context?)
Logger.Critical(eventType, thrownOrMessage, context?)
Logger.Write(event)
```

Context may contain only documented fields:

```ahk
{
    serviceId: "window_manager",
    operationId: "winmgr.resize",
    category: "operation",
    outcome: "execution-failed",
    durationMs: 18,
    properties: Map("monitor", 2)
}
```

### API behavior

- All public methods return a structured result and do not throw because persistence failed.
- `Logger.Write` validates and normalizes input before persistence.
- Unknown or unsafe properties are omitted and produce an internal sanitized reporter diagnostic where possible.
- Logging must not show a `MsgBox`.
- `Logger.Error` and `Logger.Critical` accept both AHK `Error` objects and arbitrary thrown values.
- `ErrorReporter.Report(record)` maps existing `ErrorRecord` fields into the canonical event schema.
- `ErrorReporter.Notify` remains compatible but delegates persistence and notification decisions to the new components.
- Expected cancellation and unavailability are not automatically promoted to errors.

## Success and information policy

Log these successful events by default:

- Suite and process lifecycle transitions.
- Essential and optional initialization results.
- Profile changes and safe reload outcomes.
- Configuration load/save outcomes when operationally useful.
- External or slow operations where duration helps diagnosis.
- Recovery, retry, quarantine, and restoration events.

Do not log these successful events by default:

- Every keystroke, hotkey, mouse gesture, timer tick, or GUI redraw.
- Secrets access or values derived from secrets.
- Raw clipboard activity.
- High-frequency actions without diagnostic value.

High-frequency behavior should use bounded counters or summaries, not one event per occurrence.

## Redaction and data safety

Redaction happens before an event reaches any sink, dashboard model, fallback file, or notification.

At minimum, redact:

- Current clipboard text when length is at least four characters.
- `Secrets.<name>` references.
- URL query strings, fragments, user information, and paths classified as sensitive.
- Authorization headers, API keys, tokens, passwords, cookies, and connection strings.
- Raw callable arguments.
- Values registered by the Secrets subsystem where safely possible.

Rules:

- Prefer allowlisted metadata over attempting to redact arbitrary objects.
- Never serialize arbitrary AHK objects recursively.
- Cap message, stack, and property lengths.
- Prevent CR/LF values from creating extra physical JSONL records.
- Dashboard copy actions copy sanitized data only.
- Fallback logging applies the same redaction contract.
- A redaction failure drops the risky field rather than writing it raw.

## File sink behavior

- Serialize one event entirely in memory, then append it in one file operation.
- Escape JSON correctly and keep each event on one physical line.
- Flush `error` and `critical` events promptly.
- A failed primary append returns `{ok: false}` and attempts the bounded fallback sink once.
- Fallback failure is swallowed after returning a failure result; it must not recurse.
- Process files rotate at 2 MiB by default.
- Rotated names contain a timestamp and sequence to prevent collisions.
- Keep at most five rotated segments per active process file in addition to retention rules.
- Dashboard readers treat an incomplete final line as pending and retry it after the next poll.
- A malformed complete line is skipped, counted, and shown as a dashboard reader warning without stopping other files.

## Retention policy

Defaults:

- Maximum age: 14 days.
- Maximum total log storage: 100 MiB.
- Never delete the active suite run.
- Under the size limit, delete oldest completed runs first.
- Do not delete individual files from the middle of a retained completed run unless the run itself exceeds the complete storage budget.
- If one completed run alone exceeds the budget, keep its newest bounded process segments and record a cleanup summary.
- Cleanup failures do not block Startup.
- The dashboard offers an explicit `Delete history` action with confirmation.
- Manual deletion never targets the active run.

## Notification policy

| Level/event | Persist | Notify by default |
|---|---:|---:|
| `debug` | only when enabled | no |
| routine `info` | yes, selectively | no |
| `warning` | yes | configurable |
| `error` | yes | yes, rate-limited |
| `critical` | yes | yes |
| expected cancellation | optional info | no |

Rate limiting uses `fingerprint + serviceId`:

- Notify immediately on the first occurrence.
- Suppress matching notifications for 60 seconds.
- Continue counting or recording occurrences during suppression.
- After the window, show at most one summary notification containing the repeated count.
- Never include raw exception text or sensitive values in notifications.
- Dashboard health remains degraded after the transient notification closes.

## Dashboard functional specification

### Launch and lifetime

- Add `Diagnostics` to the Startup tray menu.
- Opening Diagnostics shows or activates one dashboard instance.
- Closing the window hides or exits only the dashboard, never logging or suite services.
- The dashboard may be launched independently and discover the newest active run.
- Dashboard startup failure must not affect Startup or child processes.

### Overview

Show:

- Overall state: `Healthy`, `Degraded`, or `Critical`.
- Selected suite run ID, profile, start time, and elapsed time.
- Number of discovered processes and services.
- Counts by level.
- Latest error time.
- Services with recent errors or degraded state.

State calculation:

- `Critical` when a critical event or required service failure is active.
- `Degraded` when warnings, recoverable errors, quarantined optional services, or malformed log input exist.
- `Healthy` when no active degraded or critical condition exists.
- Historical errors do not permanently mark a recovered service degraded when an explicit recovery/ready event supersedes them.

### Event list

- Default scope is the active/current suite run.
- Merge process files by parsed timestamp, then process run ID and sequence for deterministic ties.
- Newest events appear first by default.
- Provide filters for level, service, operation, category, event type, and free text.
- Provide an `Errors only` shortcut.
- Provide pause/resume live updates; pausing display does not stop reading or logging.
- Preserve selection when new events arrive where practical.
- Limit rendered rows through paging or virtualization; do not create an unbounded number of GUI controls.

### Event details

Show sanitized:

- Timestamp and level.
- Service, process, operation, category, and outcome.
- Message.
- Duration.
- Error type, source file, line, `What`, and stack.
- Event, run, process, and fingerprint IDs.
- Allowlisted properties.

Actions:

- Copy sanitized summary.
- Copy sanitized JSON.
- Open source file at line when the path exists and is inside an allowed local source root.
- Open the containing log folder.

### Repeated failures

- Group matching `fingerprint + serviceId + operationId` failures.
- Display occurrence count, first seen, and last seen.
- Allow expansion to individual occurrences.
- Do not group events without a fingerprint unless their event type explicitly supports aggregation.

### History

- Discover runs from retained run folders even when `run.json` is missing.
- Offer `Current run`, `Last run`, `Today`, `Last 7 days`, `Last 14 days`, and individual run selection.
- Clearly label active, completed, crashed/incomplete, and unknown run state.
- Switching history scope must not alter or pause production logging.
- The dashboard remembers non-sensitive UI preferences, but starts on the current run unless the user explicitly pins another scope.

### Empty and failure states

- No logs: explain that no events have been recorded and offer the log folder.
- No matching events: distinguish this from no logs.
- Malformed file: show a non-modal reader warning and continue with other files.
- Deleted file during reading: remove or mark its events without crashing.
- Access denied: show a sanitized actionable message.
- Dashboard internal error: attempt reporter logging without recursive UI failure.

## Reader and live-update contract

Maintain per-file state:

- Absolute path.
- Last observed size and modified timestamp.
- Last consumed byte offset.
- Buffered incomplete final line.
- File identity where available, to detect rotation or replacement.
- Count of malformed records.

Every 750 ms while live mode is enabled:

1. Discover new process files in the selected active run.
2. Detect truncation, rotation, deletion, or replacement.
3. Read only bytes added after the saved offset.
4. Combine bytes with the buffered incomplete line.
5. Parse complete lines independently.
6. Normalize supported schema versions.
7. Insert events into the model in deterministic order.
8. Update grouping, counts, health, filters, and visible rows.

The reader must not rewrite production log files.

## Backward compatibility and migration

The existing `%LOCALAPPDATA%\AutoHotkey Workflow\Logs\error.log.jsonl` format may exist before the new run layout.

- Treat it as `Legacy logs` in the dashboard.
- Read it best-effort using the current `ErrorRecord` fields.
- Do not rewrite or move it automatically in version 1.
- New events use only the new run/process layout after migration is enabled.
- Keep `ErrorReporter.Report` and `ErrorReporter.Notify` callable throughout migration.
- Existing callers should not require a flag-day update.

## Performance budgets

- A normal log append should complete within 10 ms at the 95th percentile on the local machine, excluding exceptional antivirus or disk stalls.
- Logging must avoid WebView, network, UIA, and shell startup.
- Dashboard polling should average under 2% CPU when idle.
- Dashboard initial display of 10,000 retained events should complete within 2 seconds on the target machine.
- The dashboard must remain usable with at least 50,000 events across retained runs.
- Event message plus properties is capped at 32 KiB after sanitization; stack is capped separately at 16 KiB.
- In-memory dashboard event retention is bounded and documented.

## Reliability invariants

- No logging failure may terminate the caller.
- No dashboard failure may terminate Startup or another service.
- No event may cause recursive reporter calls without a fixed termination bound.
- No malformed line may prevent later valid lines from loading.
- No process writes to another process's primary JSONL file.
- No automatic cleanup deletes the active run.
- No notification path uses `MsgBox` for production errors.
- No raw sensitive value is written before redaction.
- Log ordering never relies only on filesystem enumeration order.
- All timers and GUI callbacks introduced by diagnostics use safe callback boundaries.
- AutoHotkey v2 syntax validation is required for every changed production entrypoint.

## Proposed source structure

Names may change only if the same responsibilities remain explicit.

```text
Lib\Core\Diagnostics\
├── LogEvent.ahk
├── Logger.ahk
├── LogContext.ahk
├── LogRedactor.ahk
├── JsonlLogSink.ahk
├── NotificationPolicy.ahk
├── LogRetention.ahk
├── LogReader.ahk
└── LogQuery.ahk

Dashboards\Diagnostics\
├── Diagnostics Dashboard.ahk
├── DiagnosticsController.ahk
├── DiagnosticsViewModel.ahk
└── DiagnosticsView.ahk

Tests\Logging\
├── Test_LogEvent.ahk
├── Test_LogRedactor.ahk
├── Test_JsonlLogSink.ahk
├── Test_RunContext.ahk
├── Test_LogRetention.ahk
├── Test_LogReader.ahk
├── Test_NotificationPolicy.ahk
└── Interactive_Diagnostics_Demo.ahk
```

## Implementation tasks

Tasks must be completed in order unless a dependency statement explicitly allows parallel work. Each completed task must add verification evidence to this document or a linked verification artifact.

### Phase 0 — Baseline and contracts

- [ ] **LOG-001 — Capture baseline.** Inventory every `ErrorReporter`, `SafeCall`, notification, error `MsgBox`, empty catch, lifecycle, and existing log path in first-party production code. Record current files, formats, entrypoints, and known concurrency risks.
- [ ] **LOG-002 — Freeze schema fixtures.** Add sanitized valid and invalid schema-v1 JSONL fixtures covering every required field, all levels, arbitrary thrown values, multiline text, Unicode, and malformed final lines.
- [ ] **LOG-003 — Define supported AHK/runtime environment.** Record the exact AutoHotkey v2 executable discovery rule, supported Windows versions, encoding, path-length expectations, and timestamp-offset implementation.
- [ ] **LOG-004 — Add automated validation harness.** Provide one command that validates all new diagnostic modules, dashboard entrypoints, tests, and affected production entrypoints with `/Validate /ErrorStdOut` and fails on warnings.

### Phase 1 — Event and context foundation

- [ ] **LOG-005 — Implement `LogContext`.** Create and validate suite-run, process-run, PID, service, profile, and sequence identities. Support inheritance through `AHK_SUITE_RUN_ID` and safe standalone fallback.
- [ ] **LOG-006 — Integrate suite-run creation.** Update Startup to create exactly one suite run before launching children, write bounded run metadata, and ensure child processes inherit the ID.
- [ ] **LOG-007 — Implement canonical `LogEvent`.** Validate levels, categories, event types, outcomes, IDs, timestamps, optional error information, allowlisted properties, and maximum lengths.
- [ ] **LOG-008 — Implement robust JSON serialization/parsing.** Correctly handle quotes, slashes, control characters, newlines, tabs, Unicode, numbers, booleans, null-equivalent fields, arrays/maps where explicitly supported, and one-line output.
- [ ] **LOG-009 — Implement event IDs and ordering.** Guarantee uniqueness within practical local constraints and monotonically increasing process sequence values.

### Phase 2 — Safety and persistence

- [ ] **LOG-010 — Implement `LogRedactor`.** Cover clipboard, Secrets references and registered values, credentials, URL components, headers, tokens, connection strings, raw arguments, nested allowed metadata, and length caps.
- [ ] **LOG-011 — Add adversarial redaction tests.** Verify case variants, separators, Unicode, partial matches, multiline data, overlapping secrets, empty clipboard, short clipboard values, and redaction failure behavior.
- [ ] **LOG-012 — Implement per-process JSONL sink.** Create the run layout, append one complete event per operation, prevent cross-process primary writes, and return structured results without throwing.
- [ ] **LOG-013 — Implement bounded fallback sink.** Use the fallback folder, prevent recursion, retain minimal sanitized diagnostics, and safely handle primary plus fallback failure.
- [ ] **LOG-014 — Implement file rotation.** Rotate process segments at 2 MiB, avoid filename collisions, retain five segments, and remain correct if rotation itself fails.
- [ ] **LOG-015 — Implement retention.** Enforce 14 days and 100 MiB, preserve the active run, delete oldest completed runs first, handle partial runs, and expose dry-run output for tests.
- [ ] **LOG-016 — Implement `Logger`.** Add level methods, normalization, redaction, sink dispatch, structured results, debug enablement, and recursion guards.
- [ ] **LOG-017 — Adapt `ErrorReporter`.** Preserve current public calls while mapping `ErrorRecord` into schema-v1 events and removing duplicate persistence/notification responsibilities.
- [ ] **LOG-018 — Integrate `SafeCall`.** Emit consistent operation failure events and selected duration/outcome data without double-reporting failures.

### Phase 3 — Notification behavior

- [ ] **LOG-019 — Implement notification policy.** Separate notification from persistence, map levels to behavior, sanitize text, and use native TrayTip fallback.
- [ ] **LOG-020 — Implement fingerprint throttling.** Notify the first occurrence, suppress repeats for 60 seconds, maintain counts, and issue at most one later summary.
- [ ] **LOG-021 — Verify notification resilience.** Demonstrate that unavailable notifications, TrayTip failure, repeated timer errors, and dashboard absence never block or terminate callers.

### Phase 4 — Incremental reader and query model

- [ ] **LOG-022 — Implement run discovery.** Find active, completed, incomplete, standalone, historical, and legacy runs without trusting `run.json` as the only source.
- [ ] **LOG-023 — Implement incremental JSONL reader.** Track offsets, buffer incomplete lines, detect rotation/truncation/deletion, parse lines independently, and continue after malformed input.
- [ ] **LOG-024 — Implement deterministic merge.** Merge events across process files by timestamp, process run ID, and sequence without losing late-arriving events.
- [ ] **LOG-025 — Implement query and grouping.** Filter by run, time, level, service, operation, category, event type, free text, and fingerprint; calculate occurrence summaries.
- [ ] **LOG-026 — Implement health projection.** Derive Healthy/Degraded/Critical state and support recovery events that supersede earlier failures.
- [ ] **LOG-027 — Add legacy reader.** Display the existing `error.log.jsonl` as read-only `Legacy logs` without automatically rewriting it.

### Phase 5 — Dashboard UX

- [ ] **LOG-028 — Build dashboard shell.** Create a single-instance native AHK dashboard with safe startup, close behavior, refresh timer, loading, empty, and failure states.
- [ ] **LOG-029 — Build overview.** Show health, selected run, profile, elapsed time, process/service counts, level counts, latest error, and degraded services.
- [ ] **LOG-030 — Build event list.** Add deterministic rows, level styling, filters, search, errors-only shortcut, live pause/resume, bounded rendering, and stable selection.
- [ ] **LOG-031 — Build detail panel.** Show all sanitized schema fields and implement copy-summary, copy-JSON, open-source, and open-log-folder actions safely.
- [ ] **LOG-032 — Build repeated-failure UX.** Group by fingerprint/service/operation, show first/last/count, and expand individual occurrences.
- [ ] **LOG-033 — Build history UX.** Add current/last/today/7-day/14-day/individual-run scopes and clearly label active, completed, crashed, and unknown runs.
- [ ] **LOG-034 — Add retention controls.** Show disk usage and retention settings; add confirmed history deletion that cannot select the active run.
- [ ] **LOG-035 — Integrate Startup tray.** Add `Diagnostics`, activate an existing dashboard instance, and ensure launch failure leaves Startup and children unaffected.
- [ ] **LOG-036 — Add accessibility and usability pass.** Verify keyboard navigation, readable scaling, clear timestamps, non-color-only severity indicators, copy feedback, focus behavior, and useful error wording.

### Phase 6 — Production instrumentation

- [ ] **LOG-037 — Instrument suite lifecycle.** Emit suite/process starting, ready, degraded, stopping, exited, and failed events with correct intentional-exit classification.
- [ ] **LOG-038 — Instrument initialization.** Record essential and optional component outcomes without leaking configuration or secrets.
- [ ] **LOG-039 — Instrument meaningful successes.** Add only approved lifecycle, configuration, slow/external operation, recovery, and profile/reload outcomes; document why each success event is useful.
- [ ] **LOG-040 — Audit high-frequency paths.** Ensure hotkeys, mouse actions, timer ticks, and GUI rendering do not create unbounded info logs; introduce bounded summaries only where useful.
- [ ] **LOG-041 — Migrate production errors.** Route first-party unexpected failures through Logger/ErrorReporter while preserving expected outcomes and avoiding double reports.
- [ ] **LOG-042 — Add service and operation catalog.** Document stable IDs and event types; reject or flag accidental variants in tests.

### Phase 7 — Verification and rollout

- [ ] **LOG-043 — Run unit verification.** Pass schema, JSON, identity, redaction, sink, fallback, rotation, retention, notification, reader, merge, query, grouping, and health tests.
- [ ] **LOG-044 — Run multi-process verification.** Launch multiple writers under one suite run, demonstrate separate files, verify no corruption, and confirm deterministic dashboard merge.
- [ ] **LOG-045 — Run failure-injection verification.** Test denied directories, full/unavailable disk simulation where safe, malformed JSONL, incomplete writes, file deletion, rotation during reading, invalid run metadata, and dashboard exceptions.
- [ ] **LOG-046 — Run security verification.** Seed unique clipboard, URL, token, password, Secrets, argument, and configuration markers and prove none appear in any primary file, fallback file, notification, dashboard row, details, or copied output.
- [ ] **LOG-047 — Run performance verification.** Measure append latency, idle dashboard CPU, 10,000-event startup, 50,000-event usability, memory bounds, and retention cleanup time.
- [ ] **LOG-048 — Run regression verification.** Validate and manually smoke-test Startup, profiles, reload, exit, hotkeys, timers, menus, dashboards, and all changed production entrypoints.
- [ ] **LOG-049 — Run interactive acceptance demo.** Demonstrate current-run live updates, history switching, repeated-error grouping, recovery, notification throttling, log-folder access, dashboard restart, and continued suite operation after dashboard failure.
- [ ] **LOG-050 — Document operations.** Explain log location, dashboard use, levels, retention, clearing history, adding new events, selecting safe properties, diagnosing reporter failure, and changing debug mode.
- [ ] **LOG-051 — Observe stable usage.** Complete an agreed real-world observation period with no blocking production error dialogs, unbounded growth, notification storms, corrupted logs, material idle overhead, or secret leakage.

## Acceptance specifications

The following statements are testable requirements and must all be true.

### Identity and current run

- [ ] **SPEC-RUN-001** — Starting `Startup.ahk` creates exactly one valid suite run ID.
- [ ] **SPEC-RUN-002** — Every process launched by that Startup instance records the same suite run ID.
- [ ] **SPEC-RUN-003** — Each process has a distinct process run ID and primary file.
- [ ] **SPEC-RUN-004** — An independently started application creates a valid standalone run when no inherited ID exists.
- [ ] **SPEC-RUN-005** — Reloading or restarting a process creates a new process run ID without changing the suite run ID unless Startup itself begins a new run.
- [ ] **SPEC-RUN-006** — The dashboard selects the newest active suite run by default.

### Persistence and resilience

- [ ] **SPEC-STORE-001** — Every valid event produces exactly one complete physical JSONL line in its process file.
- [ ] **SPEC-STORE-002** — Concurrent processes do not corrupt or interleave primary event lines.
- [ ] **SPEC-STORE-003** — A primary write failure returns safely and attempts the fallback at most once.
- [ ] **SPEC-STORE-004** — Primary plus fallback failure never propagates an exception to the caller.
- [ ] **SPEC-STORE-005** — Rotation never prevents the triggering event from being written where storage remains available.
- [ ] **SPEC-STORE-006** — Automatic retention never deletes the active run.
- [ ] **SPEC-STORE-007** — Completed runs older than 14 days are eligible for deletion.
- [ ] **SPEC-STORE-008** — Total retained storage converges to at most 100 MiB subject to preserving the active run.
- [ ] **SPEC-STORE-009** — Production logs are not written inside the repository.

### Schema and safety

- [ ] **SPEC-SCHEMA-001** — Every new event satisfies canonical schema version 1.
- [ ] **SPEC-SCHEMA-002** — Unknown level, category, outcome, or malformed required fields are rejected or safely normalized according to documented rules.
- [ ] **SPEC-SCHEMA-003** — Event ordering is deterministic when timestamps are equal.
- [ ] **SPEC-SAFE-001** — Test secret markers never appear in primary logs, fallback logs, notifications, dashboard state, or copied text.
- [ ] **SPEC-SAFE-002** — Multiline and control-character input cannot create extra JSONL records.
- [ ] **SPEC-SAFE-003** — Arbitrary thrown values are normalized without escaping the error boundary.
- [ ] **SPEC-SAFE-004** — Oversized fields are truncated with an explicit safe marker.
- [ ] **SPEC-SAFE-005** — Arbitrary objects and raw callback arguments are never recursively serialized.

### Levels, outcomes, and noise

- [ ] **SPEC-LEVEL-001** — Only the five defined levels are emitted.
- [ ] **SPEC-LEVEL-002** — Successful operations use `outcome: success`, normally at `info`, rather than a success severity.
- [ ] **SPEC-LEVEL-003** — Expected cancellation does not generate an error event or notification.
- [ ] **SPEC-LEVEL-004** — Debug events are not persisted under default production configuration.
- [ ] **SPEC-LEVEL-005** — A frequent timer or hotkey can run for ten minutes without producing unbounded routine success events.

### Notifications

- [ ] **SPEC-NOTIFY-001** — Logging works while the dashboard is closed.
- [ ] **SPEC-NOTIFY-002** — Persisting an event does not require successful notification.
- [ ] **SPEC-NOTIFY-003** — Repeating one fingerprint many times within 60 seconds produces at most one immediate notification.
- [ ] **SPEC-NOTIFY-004** — Notifications contain only sanitized user-safe summaries.
- [ ] **SPEC-NOTIFY-005** — Production diagnostic paths do not display blocking `MsgBox` dialogs.

### Reader and dashboard

- [ ] **SPEC-UI-001** — The dashboard displays new current-run events within two polling intervals under normal local conditions.
- [ ] **SPEC-UI-002** — A partial final JSONL line is not reported as permanently malformed and becomes visible after completion.
- [ ] **SPEC-UI-003** — One malformed complete line does not hide valid lines before or after it.
- [ ] **SPEC-UI-004** — Rotation, truncation, deletion, or replacement of one file does not crash the dashboard.
- [ ] **SPEC-UI-005** — Events from multiple process files are merged deterministically.
- [ ] **SPEC-UI-006** — Filters and free-text search operate on sanitized visible data.
- [ ] **SPEC-UI-007** — Repeated failures group by fingerprint, service, and operation and expose count/first/last occurrence.
- [ ] **SPEC-UI-008** — Recovery/ready events can return a service and suite from degraded to healthy state.
- [ ] **SPEC-UI-009** — Historical run selection never changes production logging behavior.
- [ ] **SPEC-UI-010** — Dashboard failure or closure leaves Startup, services, and logging active.
- [ ] **SPEC-UI-011** — The user can open Diagnostics from the Startup tray and activate an already-running dashboard.
- [ ] **SPEC-UI-012** — The user can inspect legacy error logs without those files being rewritten.

### Performance

- [ ] **SPEC-PERF-001** — Normal local append latency meets the documented 10 ms p95 target in the verification environment.
- [ ] **SPEC-PERF-002** — Idle dashboard CPU averages below 2% in the verification environment.
- [ ] **SPEC-PERF-003** — Ten thousand events become inspectable within two seconds in the verification environment.
- [ ] **SPEC-PERF-004** — Fifty thousand retained events do not cause unbounded controls, memory, or UI lockup.

## Required test scenarios

Automated tests should use isolated temporary roots and unique synthetic secret markers.

1. Valid event round-trip for every level and optional field combination.
2. Error object and string thrown-value normalization.
3. JSON escaping for quotes, slashes, tabs, CR/LF, emoji, and non-Latin text.
4. Redaction of clipboard, URLs, credentials, tokens, Secrets references, and overlapping values.
5. Primary sink failure and successful fallback.
6. Primary plus fallback failure.
7. Rotation at, below, and above the boundary.
8. Rotation filename collision.
9. Age and size retention with active-run protection.
10. Multiple simultaneous process writers under one suite run.
11. Incremental read with line split across multiple polls.
12. Malformed middle line followed by valid events.
13. File rotation, truncation, replacement, and deletion during live reading.
14. Equal timestamps across processes with deterministic tie-breaking.
15. Notification burst of one fingerprint and mixed fingerprints.
16. Dashboard launch, second launch activation, close, and relaunch.
17. Current-run selection and historical navigation.
18. Filters, search, grouping, expansion, copy, and open-folder behavior.
19. Health transition from healthy to degraded/critical and back after recovery.
20. Dashboard-internal failure while suite logging continues.
21. Existing `ErrorReporter` callers through the compatibility adapter.
22. Legacy `error.log.jsonl` discovery and display.
23. High-frequency timer/hotkey noise-budget test.
24. End-to-end interactive demonstration with actual AHK callbacks.

## AI implementation protocol

When an AI implements this plan, it must:

1. Read this entire document and relevant existing error-resilience specifications before editing.
2. Select the first unchecked task whose prerequisites are complete.
3. Inspect current code and tests; never assume planned files already exist.
4. Implement only that task and any strictly required supporting change.
5. Preserve existing user changes and backward compatibility unless the task explicitly changes a contract.
6. Use narrow includes and keep diagnostics independent of optional UI/WebView/UIA/internet modules.
7. Add or update automated tests for every behavioral change.
8. Validate every changed AHK entrypoint using the installed production AutoHotkey v2 interpreter and `/Validate /ErrorStdOut`.
9. Run relevant runtime tests, including negative and failure-injection cases.
10. Check for secret markers in every produced artifact.
11. Record commands, results, and requirement IDs as verification evidence.
12. Mark a task complete only when its acceptance evidence passes.
13. Stop at phase boundaries for human review before beginning the next phase.
14. Never weaken redaction, retention, error containment, or process isolation merely to make a test pass.

## Phase gates

- [ ] **GATE-0 — Contract approval.** User approves goals, locked decisions, schema, retention, dashboard scope, and implementation protocol.
- [ ] **GATE-1 — Foundation approval.** Run context, schema, serializer, and fixtures are reviewed before production persistence changes.
- [ ] **GATE-2 — Logger approval.** Redaction, sinks, retention, Logger, compatibility, and notifications pass failure/security tests before dashboard work.
- [ ] **GATE-3 — Reader approval.** Run discovery, incremental reading, merge, query, grouping, health, and legacy behavior pass before UI integration.
- [ ] **GATE-4 — Dashboard approval.** Dashboard UX and Startup tray integration pass interactive review before broad instrumentation.
- [ ] **GATE-5 — Production rollout approval.** Instrumentation, regression, security, performance, documentation, and observation evidence are accepted.

## Definition of done

The logging and diagnostics project is fully complete only when:

- [ ] LOG-001 through LOG-051 are complete with evidence.
- [ ] GATE-0 through GATE-5 are explicitly approved.
- [ ] Every `SPEC-*` statement has passing automated or documented manual evidence.
- [ ] Production logging uses per-suite-run, per-process JSONL storage outside the repository.
- [ ] Current and historical runs are usable from the dashboard.
- [ ] Dashboard absence or failure has no effect on logging or suite functionality.
- [ ] Reporter and fallback failures cannot terminate callers or recurse indefinitely.
- [ ] Notification storms are prevented.
- [ ] Retention prevents unbounded disk usage without deleting the active run.
- [ ] No seeded sensitive marker appears in any persisted or displayed output.
- [ ] Existing error-reporting callers remain functional after migration.
- [ ] All affected production entrypoints validate and regression tests pass.
- [ ] The user approves the interactive dashboard and history workflow.

