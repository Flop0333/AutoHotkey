# Error Resilience Execution Ledger

Copilot executes one `READY` task per run according to `Error Plan/AGENTS.md`.

## State rules

- Status: `PENDING`, `READY`, `IN-PROGRESS`, `BLOCKED`, `DONE`, `REVIEW`.
- Complete acceptance and verification before `DONE`.
- Then promote the next dependency-satisfied task in the same phase, or set the gate to `REVIEW`; stop afterward.
- Human approval changes a gate from `REVIEW` to `DONE` and promotes the first next-phase task.
- Completion evidence is permanent project history.

---

## Phase 1 — Inventory and contracts

### TASK-ERR-001 — Production service inventory

**Status:** READY  
**Implements:** REQ-ENTRY-001, DEC-ERR-001  
**Dependencies:** None

**Deliverables:** Populate `service-inventory.md` from `Startup/Startup.ahk` and indirect launches; record baseline startup/reload/profile/exit and representative failure behavior.

**Acceptance:** Every production entrypoint has all required columns; persistent vs one-shot is explicit; third-party examples are excluded; no production code changes.

**Verification:** Cross-check inventory paths against repository files and startup launch graph.

**Evidence:** Files — | Checks — | Result — | Assumptions —

### TASK-ERR-002 — Error-path and dependency audit

**Status:** PENDING  
**Implements:** REQ-MIG-001 through REQ-MIG-003, REQ-DEP-005  
**Dependencies:** TASK-ERR-001

**Deliverables:** Populate source-audit section for MsgBox/throw/catch/try/ExitApp/Reload, callback registrations, static initialization, Core includes, and cycles.

**Acceptance:** Every first-party production occurrence is classified with intended future boundary; no behavior changes.

**Verification:** Repeatable `rg` searches documented and counts reconciled.

**Evidence:** Files — | Checks — | Result — | Assumptions —

### TASK-ERR-003 — Offline error test harness

**Status:** PENDING  
**Implements:** DEC-ERR-009  
**Dependencies:** TASK-ERR-001

**Deliverables:** `Tests/Error Resilience/Run Error Tests.ahk`, framework/assertions, temp-directory helpers, passing and deliberate-failure proof.

**Acceptance:** Offline; exit 0/1; readable failures; cannot touch real runtime/log directories or unrelated processes.

**Verification:** Demonstrate fail then restored pass.

**Evidence:** Files — | Tests — | Result — | Assumptions —

### TASK-ERR-004 — Service and result models

**Status:** PENDING  
**Implements:** REQ-ENTRY-001, REQ-ENTRY-003, DEC-ERR-002  
**Dependencies:** TASK-ERR-003

**Deliverables:** `ServiceDefinition`, `OperationResult`, restart/health policy models and unit tests.

**Acceptance:** Validated immutable/safely copied fields; stable statuses; invalid policies and contradictory definitions fail clearly.

**Verification:** Full error suite.

**Evidence:** Files — | Tests — | Result — | Assumptions —

### TASK-ERR-005 — Service manifest

**Status:** PENDING  
**Implements:** REQ-ENTRY-001, REQ-ENTRY-003  
**Dependencies:** TASK-ERR-004

**Deliverables:** Authoritative manifest reproducing inventory/profile behavior; validation tests.

**Acceptance:** No duplicate ID/script conflict; every current launch represented; filtering matches current profiles; startup still uses old launch path for now.

**Verification:** Full suite and manifest-to-inventory comparison.

**Evidence:** Files — | Tests — | Result — | Assumptions —

### GATE-ERR-001 — Inventory/contracts review

**Status:** PENDING  
**Dependencies:** TASK-ERR-001 through TASK-ERR-005

Human reviews scope, baseline, manifest, categories, criticality, and test isolation.

---

## Phase 2 — Reporter and safe runtime boundaries

### TASK-ERR-006 — ErrorRecord and fingerprint

**Status:** PENDING  
**Implements:** REQ-ERR-001 through REQ-ERR-003, REQ-ERR-009  
**Dependencies:** GATE-ERR-001

**Deliverables:** `ErrorRecord`, factory for Error/non-Error, fingerprint function, tests.

**Acceptance:** Complete safe fields where available; construction never throws due to unusual thrown values; deterministic fingerprints.

**Verification:** Full suite.

**Evidence:** Files — | Tests — | Result — | Assumptions —

### TASK-ERR-007 — Redactor and bounded log writer

**Status:** PENDING  
**Implements:** REQ-ERR-006 through REQ-ERR-008, DEC-ERR-006  
**Dependencies:** TASK-ERR-006

**Deliverables:** redactor, JSONL writer, text fallback, rotation/retention tests.

**Acceptance:** Seeded secrets/clipboard/arguments/URL credentials absent; 2 MiB/five-file policy; temp paths in tests; fallback non-recursive.

**Verification:** Full suite plus sensitive marker scan.

**Evidence:** Files — | Tests — | Result — | Assumptions —

### TASK-ERR-008 — Notification interface and fallback

**Status:** PENDING  
**Implements:** REQ-NOTIFY-001 through REQ-NOTIFY-005  
**Dependencies:** TASK-ERR-006

**Deliverables:** notification contract, native tray fallback, coalescing/rate-limit model, fakes/tests.

**Acceptance:** Non-modal/auto-close; repeated fingerprint count; sanitized text; confirmation API separate; preferred UI failure falls back.

**Verification:** Full suite and manual fallback demonstration.

**Evidence:** Files — | Tests/manual — | Result — | Assumptions —

### TASK-ERR-009 — ErrorReporter

**Status:** PENDING  
**Implements:** REQ-ERR-004, REQ-ERR-005, REQ-ERR-009, REQ-QUAL-002  
**Dependencies:** TASK-ERR-007, TASK-ERR-008

**Deliverables:** minimal `ErrorReporter`, injected writer/notifier, reporter-failure tests.

**Acceptance:** One reporting path; no recursion; no optional UI/web dependencies; user-safe and diagnostic messages separated.

**Verification:** Full suite including simultaneous writer/notifier failure.

**Evidence:** Files — | Tests — | Result — | Assumptions —

### TASK-ERR-010 — SafeCall

**Status:** PENDING  
**Implements:** REQ-SAFE-001 through REQ-SAFE-004  
**Dependencies:** TASK-ERR-004, TASK-ERR-009

**Deliverables:** `SafeCall`, context model, success/expected/throw/fallback/reporter-failure tests.

**Acceptance:** Exact once; stable operation ID; structured results; duration/service context; expected outcomes not reported; unexpected never swallowed.

**Verification:** Full suite.

**Evidence:** Files — | Tests — | Result — | Assumptions —

### TASK-ERR-011 — Callback adapters

**Status:** PENDING  
**Implements:** REQ-SAFE-005, REQ-SAFE-006  
**Dependencies:** TASK-ERR-010

**Deliverables:** adapters and tests for hotkey/hotstring, timer, GUI/control, clipboard, menu, gesture, and audited other callbacks.

**Acceptance:** Preserve callback signature/binding; failure contained; subsequent invocation works; stable operation IDs.

**Verification:** Full suite with repeated invocation per adapter.

**Evidence:** Files — | Tests — | Result — | Assumptions —

### TASK-ERR-012 — Minimal bootstrap, OnError, and OnExit

**Status:** PENDING  
**Implements:** REQ-GLOBAL-001 through REQ-GLOBAL-005  
**Dependencies:** TASK-ERR-009, TASK-ERR-010

**Deliverables:** minimal service bootstrap, lifecycle reason contract, fallback tests.

**Acceptance:** Registered before optional init; handles arbitrary thrown values; suppresses dialog; never continues; no slow/modal dependency; no double report.

**Verification:** Full suite and isolated fixture-process checks.

**Evidence:** Files — | Tests — | Result — | Assumptions —

### GATE-ERR-002 — Runtime containment review

**Status:** PENDING  
**Dependencies:** TASK-ERR-006 through TASK-ERR-012

Human reviews redaction, reporter independence, notification behavior, SafeCall semantics, and global fallback safety.

---

## Phase 3 — Validation and supervision

### TASK-ERR-013 — Entrypoint validator

**Status:** PENDING  
**Implements:** REQ-VAL-001 through REQ-VAL-003  
**Dependencies:** GATE-ERR-002, TASK-ERR-005

**Deliverables:** validator, interpreter resolution, valid/syntax/missing-include fixtures and tests.

**Acceptance:** `/Validate /ErrorStdOut`; structured diagnostic; validate-all continues; aggregate non-zero result.

**Verification:** Full suite against fixtures.

**Evidence:** Files — | Tests — | Result — | Assumptions —

### TASK-ERR-014 — Explicit entrypoint directives and identity

**Status:** PENDING  
**Implements:** REQ-ENTRY-002  
**Dependencies:** TASK-ERR-013

**Deliverables:** add explicit directives/bootstrap identity to production entrypoints incrementally; update inventory.

**Acceptance:** Same user behavior; all manifest entries validate; directive ownership no longer inherited from Core for migrated entries.

**Verification:** Full suite and complete manifest validation.

**Evidence:** Files — | Tests — | Result — | Assumptions —

### TASK-ERR-015 — Status-file runtime

**Status:** PENDING  
**Implements:** REQ-SVC-001, REQ-SVC-003 through REQ-SVC-005, DEC-ERR-007  
**Dependencies:** TASK-ERR-012

**Deliverables:** atomic status writer/reader, initialization-step API, stale-PID cleanup tests.

**Acceptance:** Correct states/PID/time; essential vs optional results; no network; corrupt/stale files safe.

**Verification:** Full suite with temporary runtime directory.

**Evidence:** Files — | Tests — | Result — | Assumptions —

### TASK-ERR-016 — PID-specific launcher and monitor

**Status:** PENDING  
**Implements:** REQ-SVC-002, REQ-SVC-006, REQ-SVC-011  
**Dependencies:** TASK-ERR-005, TASK-ERR-013, TASK-ERR-015

**Deliverables:** launch quoting/PID capture, startup timeout, exact-PID monitor and fixture-service tests.

**Acceptance:** No process-name matching; no kill-all; missing/failed service doesn't block others; PID ownership verified before control.

**Verification:** Full suite with isolated fixture processes.

**Evidence:** Files — | Tests — | Result — | Assumptions —

### TASK-ERR-017 — Restart policy and quarantine

**Status:** PENDING  
**Implements:** REQ-SVC-007 through REQ-SVC-010, DEC-ERR-008  
**Dependencies:** TASK-ERR-016

**Deliverables:** restart budget/state machine, stability reset, intentional lifecycle handling, tests.

**Acceptance:** 1/5/20 delays; three in ten minutes; quarantine; 30-minute reset; healthy siblings untouched; intentional exits never restart.

**Verification:** Full deterministic-clock suite.

**Evidence:** Files — | Tests — | Result — | Assumptions —

### TASK-ERR-018 — Two-phase lifecycle operations

**Status:** PENDING  
**Implements:** REQ-VAL-004, REQ-VAL-005, REQ-SVC-012  
**Dependencies:** TASK-ERR-016, TASK-ERR-017

**Deliverables:** validate/start/stop/restart, safe per-service/full reload, profile transition preflight, restart-failed.

**Acceptance:** Any preflight failure changes no current valid process; precise PID control; remaining launches continue after one failure.

**Verification:** Full fixture supervisor suite.

**Evidence:** Files — | Tests — | Result — | Assumptions —

### GATE-ERR-003 — Supervisor review

**Status:** PENDING  
**Dependencies:** TASK-ERR-013 through TASK-ERR-018

Human reviews validation evidence, process precision, lifecycle semantics, restart budget, and quarantine.

---

## Phase 4 — Integration and migration

### TASK-ERR-019 — Manifest-driven startup supervisor

**Status:** PENDING  
**Implements:** REQ-ENTRY-001, REQ-VAL-004, REQ-SVC-006  
**Dependencies:** GATE-ERR-003

**Deliverables:** replace repeated startup `Run()` list with manifest supervisor behind a development flag.

**Acceptance:** Launch order/profile behavior preserved; validate-first; one failure isolated; PIDs retained; rollback path documented.

**Verification:** Full suite and development-mode startup baseline comparison.

**Evidence:** Files — | Tests/manual — | Result — | Assumptions —

### TASK-ERR-020 — Status-driven startup tray

**Status:** PENDING  
**Implements:** REQ-UI-001 through REQ-UI-003, REQ-SVC-012  
**Dependencies:** TASK-ERR-018, TASK-ERR-019

**Deliverables:** overall/per-service states, disabled distinction, operations, logs/latest summary, safe tray callbacks.

**Acceptance:** Healthy/degraded/failed correct; profile/exit always available; tray errors contained; no blocking error dialogs.

**Verification:** Full suite where feasible and manual state matrix.

**Evidence:** Files — | Tests/manual — | Result — | Assumptions —

### TASK-ERR-021 — Migrate callback boundaries

**Status:** PENDING  
**Implements:** REQ-SAFE-005, REQ-SAFE-006, REQ-MIG-003  
**Dependencies:** TASK-ERR-011, TASK-ERR-019

**Deliverables:** migrate audited first-party callbacks in small documented batches; update inventory.

**Acceptance:** Every audited production callback is migrated or explicitly justified; later invocation survives injected failure.

**Verification:** Full suite plus manual callback-category failures.

**Evidence:** Files — | Tests/manual — | Result — | Assumptions —

### TASK-ERR-022 — Migrate existing error paths

**Status:** PENDING  
**Implements:** REQ-MIG-001 through REQ-MIG-003, REQ-NOTIFY-001  
**Dependencies:** TASK-ERR-009, TASK-ERR-010

**Deliverables:** resolve audited MsgBox/catch/try/ExitApp/Reload/throw paths; preserve confirmations; update audit.

**Acceptance:** No unreviewed first-party production occurrence; expected outcomes not logged; recoverable failures no longer exit/reload whole service.

**Verification:** Full suite and repeat audit searches with zero unclassified results.

**Evidence:** Files — | Tests — | Result — | Assumptions —

### TASK-ERR-023 — Minimal Core extraction

**Status:** PENDING  
**Implements:** REQ-DEP-001 through REQ-DEP-004  
**Dependencies:** TASK-ERR-012, TASK-ERR-014

**Deliverables:** minimal base and cohesive optional modules; remove directives and optional dependencies from base; tests/validation.

**Acceptance:** Reporter/bootstrap validate without WebView/UIA/apps/internet; include cycles resolved for base; no broad consumer migration yet.

**Verification:** Full suite, include audit, manifest validation.

**Evidence:** Files — | Tests — | Result — | Assumptions —

### TASK-ERR-024 — Narrow production includes

**Status:** PENDING  
**Implements:** REQ-DEP-005, REQ-QUAL-002  
**Dependencies:** TASK-ERR-023

**Deliverables:** migrate production entrypoints to narrow modules in service-sized batches; update dependency inventory.

**Acceptance:** Optional module fixture break does not invalidate unrelated services; old Core compatibility removed only after zero production consumers.

**Verification:** Full suite, manifest validation, dependency audit.

**Evidence:** Files — | Tests — | Result — | Assumptions —

### TASK-ERR-025 — Initialization boundaries and readiness

**Status:** PENDING  
**Implements:** REQ-SVC-004, REQ-SVC-005, REQ-DEP-004  
**Dependencies:** TASK-ERR-015, TASK-ERR-024

**Deliverables:** named essential/optional initialization for each persistent service and state-aware startup summary.

**Acceptance:** No false ready; named degraded step; failed child doesn't block tray; missing optional assets degrade only feature.

**Verification:** Full suite and manual essential/optional fixture failures.

**Evidence:** Files — | Tests/manual — | Result — | Assumptions —

### GATE-ERR-004 — Migration review

**Status:** PENDING  
**Dependencies:** TASK-ERR-019 through TASK-ERR-025

Human reviews behavior parity, callback/error audits, Core dependency reduction, and initialization state.

---

## Phase 5 — Hardening and release

### TASK-ERR-026 — Complete automated failure suite

**Status:** PENDING  
**Implements:** All requirements  
**Dependencies:** GATE-ERR-004

**Deliverables:** fill remaining unit/integration/security/static cases from `test-plan.md`; requirement references in test names.

**Acceptance:** All automated requirements covered; complete manifest validates; no real services harmed.

**Verification:** Run full error suite and production validation command with exit 0.

**Evidence:** Files — | Tests — | Result — | Assumptions —

### TASK-ERR-027 — Manual failure-scenario campaign

**Status:** PENDING  
**Implements:** REQ-QUAL-001 through REQ-QUAL-003  
**Dependencies:** TASK-ERR-026

**Deliverables:** populate all manual records in `verification.md` on available profiles/devices.

**Acceptance:** All ten scenarios pass or unavailable devices are explicitly recorded; no blocking dialogs, secret leakage, sibling interruption, or uncontrolled loops.

**Verification:** Human review of records and logs.

**Evidence:** Records — | Result — | Limitations —

### TASK-ERR-028 — Documentation and rollout

**Status:** PENDING  
**Implements:** REQ-QUAL-001, REQ-QUAL-003  
**Dependencies:** TASK-ERR-027

**Deliverables:** log/status/restart docs, add-service guide, safe-callback guide, outcome-vs-error guide, detailed-diagnostics guide, installation updates, flag-removal criteria.

**Acceptance:** New service/callback can be added from docs; production redaction stays default; rollout order and rollback explicit.

**Verification:** Documentation walkthrough against current implementation.

**Evidence:** Files — | Review — | Result — | Assumptions —

### TASK-ERR-029 — Final traceability and observation period

**Status:** PENDING  
**Implements:** All requirements  
**Dependencies:** TASK-ERR-028

**Deliverables:** complete `verification.md`, enable production reporting/restarts in defined order, record stable observation period.

**Acceptance:** Every requirement has evidence; no uncontrolled restart/blocking dialog; known limitations recorded; development flag removed only when rollout criteria pass.

**Verification:** Full automated suite, manifest validation, profile regression, observation record.

**Evidence:** Tests — | Profiles — | Observation — | Result —

### GATE-ERR-005 — Version 1 release review

**Status:** PENDING  
**Dependencies:** TASK-ERR-029

Human reviews `error-plan.md` definition of done and sets this gate to `DONE` only when version 1 is genuinely complete.

