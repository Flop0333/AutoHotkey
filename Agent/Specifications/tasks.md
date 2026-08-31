# Personal Agent Execution Ledger

This is the authoritative implementation state. Copilot executes one `READY` task per run.

## State rules

- Statuses: `PENDING`, `READY`, `IN-PROGRESS`, `BLOCKED`, `DONE`, `REVIEW`.
- Before editing, change the selected task from `READY` to `IN-PROGRESS`.
- Set `DONE` only after every acceptance criterion and verification passes.
- After completing a task, promote the next dependency-satisfied `PENDING` task in the same phase to `READY`; do not implement it.
- At a phase gate, set the gate to `REVIEW` and do not promote the next phase until a human changes the gate to `DONE`.
- Do not rewrite historical completion evidence.

## Verification variables

- `TEST_RUNNER`: `Apps Standalone/Personal Agent/Tests/Run Agent Tests.ahk`
- Automated verification after TASK-001: run `TEST_RUNNER` with AutoHotkey v2 and require exit code 0.
- Manual checks must record date, machine/profile, steps, and outcome.

---

## Phase 1 — Foundations

### TASK-001 — Agent test harness

**Status:** READY  
**Implements:** DEC-008  
**Dependencies:** None

**Deliverables**

- Minimal AHK v2 test framework under `Apps Standalone/Personal Agent/Tests/Framework/`.
- `Run Agent Tests.ahk` entry point.
- Assertions for equality, truth, falsehood, type, and expected exception.
- One deliberately representative passing test and documented proof that failure returns exit code 1.

**Acceptance**

- Discovers or explicitly registers tests deterministically.
- Runs without network, API key, WebView, or optional apps.
- Produces readable test names and failure details.
- Returns exit code 0/1 correctly.

**Verification:** Run a passing suite; temporarily demonstrate one failing assertion, then restore it and rerun successfully.

**Completion evidence:** Files: — | Tests: — | Result: — | Assumptions: —

### TASK-002 — Tool domain models

**Status:** PENDING  
**Implements:** REQ-TOOL-001, REQ-TOOL-002, REQ-TOOL-008  
**Dependencies:** TASK-001

**Deliverables:** `Agent Tool.ahk`, `Agent Tool Result.ahk`, focused tests.

**Acceptance:** Required fields and risk/status enums validate; mutable metadata is defensively copied; invalid callable, timeout, risk, name, or metadata produces actionable errors.

**Verification:** Full agent test suite.

**Completion evidence:** Files: — | Tests: — | Result: — | Assumptions: —

### TASK-003 — JSON-schema validator

**Status:** PENDING  
**Implements:** REQ-TOOL-004, REQ-TOOL-005, REQ-TOOL-006, DEC-007  
**Dependencies:** TASK-002

**Deliverables:** `Tool Argument Validator.ahk`, table-driven unit tests for every supported keyword and rejection case.

**Acceptance:** Validates without coercion; rejects unsupported keywords, missing required fields, wrong types, extra properties, invalid enum/ranges/lengths, and nested errors with field paths.

**Verification:** Full agent test suite.

**Completion evidence:** Files: — | Tests: — | Result: — | Assumptions: —

### TASK-004 — Agent Tool Catalogue

**Status:** PENDING  
**Implements:** REQ-API-002, REQ-TOOL-002, REQ-TOOL-003, REQ-TOOL-006, DEC-004  
**Dependencies:** TASK-003

**Deliverables:** `Agent Tool Catalogue.ahk`, schema serializer, catalogue tests.

**Acceptance:** Explicit registration only; case-stable exact lookup; duplicates fail; invalid schemas fail at registration; model JSON contains no callable or local policy metadata.

**Verification:** Full agent test suite.

**Completion evidence:** Files: — | Tests: — | Result: — | Assumptions: —

### TASK-005 — Executor and call deduplication

**Status:** PENDING  
**Implements:** REQ-TOOL-007, REQ-TOOL-008, REQ-TOOL-009  
**Dependencies:** TASK-002, TASK-004

**Deliverables:** `Agent Tool Executor.ahk`, in-memory call ledger, executor tests.

**Acceptance:** Calls the registered callable exactly once; catches exceptions; measures duration; returns structured results; duplicate call ID never repeats a side effect.

**Verification:** Full agent test suite including a counter-based duplicate execution test.

**Completion evidence:** Files: — | Tests: — | Result: — | Assumptions: —

### TASK-006 — Policy and confirmation contracts

**Status:** PENDING  
**Implements:** REQ-POL-001 through REQ-POL-006, DEC-006  
**Dependencies:** TASK-003, TASK-004

**Deliverables:** `Agent Policy.ahk`, confirmation interface plus fake, policy matrix tests.

**Acceptance:** Checks profile, availability, risk, permission, confirmation, and limits; model claims cannot alter local confirmation; destructive tools are rejected.

**Verification:** Full suite with every risk/directness/permission combination.

**Completion evidence:** Files: — | Tests: — | Result: — | Assumptions: —

### TASK-007 — Redaction and bounded audit log

**Status:** PENDING  
**Implements:** REQ-SEC-003, REQ-SEC-007, REQ-OPS-002, REQ-OPS-003, DEC-009  
**Dependencies:** TASK-002

**Deliverables:** `Sensitive Value Redactor.ahk`, `Agent Audit Log.ahk`, rotation/redaction tests.

**Acceptance:** Writes only permitted fields; redacts configured arguments and authorization-like values; rotates at 2 MiB; retains one prior file; logging failure does not block execution.

**Verification:** Full suite using temporary files only.

**Completion evidence:** Files: — | Tests: — | Result: — | Assumptions: —

### GATE-001 — Foundation review

**Status:** PENDING  
**Dependencies:** TASK-001 through TASK-007

Review contracts, schema behavior, policy matrix, security tests, and dependency direction. Human sets `DONE` to release Phase 2.

---

## Phase 2 — OpenAI and orchestration

### TASK-008 — Secret and configuration integration

**Status:** PENDING  
**Implements:** REQ-SEC-001 through REQ-SEC-003, REQ-OPS-005, DEC-001  
**Dependencies:** GATE-001

**Deliverables:** tracked `OpenAIApiKey` catalogue entry, `Agent Configuration.ahk`, isolated secrets/config tests.

**Acceptance:** Key uses current Secrets service; local values remain ignored; configuration defines model, timeouts, five-call/eight-round limits; no key appears in diagnostics.

**Verification:** Full suite and Git ignored-file check. Do not enter a real key in tests.

**Completion evidence:** Files: — | Tests: — | Result: — | Assumptions: —

### TASK-009 — Response DTOs, parser, and fake client

**Status:** PENDING  
**Implements:** REQ-API-003 through REQ-API-006  
**Dependencies:** TASK-001

**Deliverables:** response DTO/parser, `Fake Responses Client.ahk`, sanitized fixtures and contract tests.

**Acceptance:** Handles text, calls, mixed output, malformed arguments, missing call IDs, API errors, and unknown items without executing anything.

**Verification:** Full offline suite.

**Completion evidence:** Files: — | Tests: — | Result: — | Assumptions: —

### TASK-010 — Responses API HTTP client

**Status:** PENDING  
**Implements:** REQ-API-001, REQ-API-002, REQ-API-004, REQ-API-006, DEC-002  
**Dependencies:** TASK-008, TASK-009

**Deliverables:** `OpenAI Responses Client.ahk`, request builder, mocked transport tests.

**Acceptance:** Correct endpoint/headers/body; request-time key retrieval; timeouts; sanitized errors; tool schema serialization; no real network in automated tests.

**Verification:** Full suite. One optional manual live text smoke test may be documented separately.

**Completion evidence:** Files: — | Tests: — | Result: — | Assumptions: —

### TASK-011 — Text-only controller loop

**Status:** PENDING  
**Implements:** REQ-PROD-001, REQ-PROD-004, REQ-PROD-005, REQ-API-004, REQ-OPS-001  
**Dependencies:** TASK-009, TASK-010

**Deliverables:** `Agent Controller.ahk`, conversation state, controller tests.

**Acceptance:** Two-turn fake conversation; memory-only state; cancellation; sanitized transport failures; no tool support yet.

**Verification:** Full offline suite.

**Completion evidence:** Files: — | Tests: — | Result: — | Assumptions: —

### TASK-012 — Complete tool-calling loop

**Status:** PENDING  
**Implements:** REQ-PROD-002, REQ-API-002 through REQ-API-008, REQ-TOOL-007 through REQ-TOOL-009, DEC-005  
**Dependencies:** TASK-005, TASK-006, TASK-011

**Deliverables:** tool orchestration in controller and end-to-end fake-response tests.

**Acceptance:** Sequential calls; exact call IDs; validation/policy/confirmation/execution chain; limits; retry only when explicitly retryable; cancellation stops queued calls; final answer follows tool results.

**Verification:** Full suite including two dependent calls, duplicate ID, cancellation, denial, failure, and limit cases.

**Completion evidence:** Files: — | Tests: — | Result: — | Assumptions: —

### TASK-013 — Context attachment pipeline

**Status:** PENDING  
**Implements:** REQ-SEC-004 through REQ-SEC-006, REQ-CTX-001 through REQ-CTX-003, DEC-010  
**Dependencies:** TASK-011

**Deliverables:** context model/builder and providers for profile, device label, active window, visible windows, clipboard, and selection; tests.

**Acceptance:** UI/API share exact collection; sensitive context defaults off; failures isolate; attachments are labelled untrusted; hidden context is absent from request DTO.

**Verification:** Full suite with prompt-injection strings as context fixtures.

**Completion evidence:** Files: — | Tests: — | Result: — | Assumptions: —

### GATE-002 — Core-agent review

**Status:** PENDING  
**Dependencies:** TASK-008 through TASK-013

Review API boundary, fake-client coverage, context privacy, cancellation, limits, and tool-loop truthfulness. Human sets `DONE` to release Phase 3.

---

## Phase 3 — Initial tools

### TASK-014 — Read-only system and app-status tools

**Status:** PENDING  
**Implements:** REQ-INIT-001, REQ-INIT-004, REQ-TOOL-001  
**Dependencies:** GATE-002

**Deliverables:** time, profile, active-window, visible-window, and app-status definitions plus adapter tests.

**Acceptance:** Fixed schemas; safe metadata only; allowlisted app enum; unavailable apps return structured results.

**Verification:** Full suite plus documented manual window-status check.

**Completion evidence:** Files: — | Tests: — | Result: — | Assumptions: —

### TASK-015 — Application and window tools

**Status:** PENDING  
**Implements:** REQ-INIT-002, REQ-INIT-004, REQ-POL-001  
**Dependencies:** TASK-014

**Deliverables:** app launch/activate and window activate/minimize/maximize definitions and tests.

**Acceptance:** Existing adapters reused; fixed app IDs; window handles originate from current visible-window results; no executable paths from model.

**Verification:** Full suite plus manual checks for installed apps.

**Completion evidence:** Files: — | Tests: — | Result: — | Assumptions: —

### TASK-016 — URL, development, media, and timer tools

**Status:** PENDING  
**Implements:** REQ-POL-007, REQ-INIT-002, REQ-INIT-005  
**Dependencies:** TASK-014

**Deliverables:** validated URL, AutoHotkey project, Spotify playlist, and timer definitions plus tests.

**Acceptance:** URL restrictions; timer bounds; existing VS Code/Spotify/Timer code reused; failures structured; no arbitrary path or playlist ID from model.

**Verification:** Full suite plus manual checks.

**Completion evidence:** Files: — | Tests: — | Result: — | Assumptions: —

### TASK-017 — Sensitive clipboard and selection tools

**Status:** PENDING  
**Implements:** REQ-SEC-004 through REQ-SEC-007, REQ-INIT-003  
**Dependencies:** TASK-006, TASK-007, TASK-013

**Deliverables:** clipboard/selection definitions and permission/redaction tests.

**Acceptance:** Explicit opt-in; visible attachment; bounded text; raw contents never audited; contextual instructions cannot invoke tools.

**Verification:** Full security suite plus manual opt-in/cancel checks.

**Completion evidence:** Files: — | Tests: — | Result: — | Assumptions: —

### GATE-003 — Tool review

**Status:** PENDING  
**Dependencies:** TASK-014 through TASK-017

Review every schema, callable, risk, availability rule, redaction rule, and manual check. Human sets `DONE` to release Phase 4.

---

## Phase 4 — Product UI and release

### TASK-018 — WebView conversation shell

**Status:** PENDING  
**Implements:** REQ-PROD-001, REQ-PROD-003, REQ-OPS-004  
**Dependencies:** GATE-003

**Deliverables:** agent window, chat UI, bridge events, accessible keyboard behavior, UI-state tests where feasible.

**Acceptance:** Opens without API; sends text; renders roles and structured status; no raw JSON/secrets; responsive during fake delayed response.

**Verification:** Full suite and manual UI checklist.

**Completion evidence:** Files: — | Tests: — | Result: — | Assumptions: —

### TASK-019 — Confirmation, attachments, progress, and cancellation UI

**Status:** PENDING  
**Implements:** REQ-PROD-003, REQ-PROD-004, REQ-SEC-004, REQ-SEC-005, REQ-POL-003, REQ-POL-004  
**Dependencies:** TASK-018

**Deliverables:** confirmation cards, context chips, operation cards, cancel control, UI/controller integration tests.

**Acceptance:** Shows target/effect/redaction/reason; local controls alone confirm; attachments match API DTO; cancellation stops queued calls; all terminal states render.

**Verification:** Full suite and manual confirmation/cancellation matrix.

**Completion evidence:** Files: — | Tests: — | Result: — | Assumptions: —

### TASK-020 — Startup integration and complete offline scenario

**Status:** PENDING  
**Implements:** REQ-PROD-001 through REQ-PROD-005, REQ-OPS-004  
**Dependencies:** TASK-019

**Deliverables:** standalone entry point, startup/hotkey integration, complete fake-agent scenario test.

**Acceptance:** Agent starts independently and through suite; optional apps/secrets may be absent; fake scenario executes read + reversible tool and final answer; failures do not terminate suite.

**Verification:** Full suite and clean-start manual checks on available profiles.

**Completion evidence:** Files: — | Tests: — | Result: — | Assumptions: —

### TASK-021 — Security evaluation, documentation, and live smoke test

**Status:** PENDING  
**Implements:** All requirements  
**Dependencies:** TASK-020

**Deliverables:** requirement-to-test traceability table, behavioral evaluation results, setup/tool-authoring/privacy documentation, sanitized live smoke-test record.

**Acceptance:** All automated tests pass; every requirement has evidence; injection/security cases fail closed; key absent from tracked files/logs; model/tool results are truthful; limitations and API cost/data boundary documented.

**Verification:** Full suite, Git secret/ignored-file checks, behavioral evaluation, and one user-authorized live API smoke test.

**Completion evidence:** Files: — | Tests: — | Result: — | Assumptions: —

### GATE-004 — Version 1 release review

**Status:** PENDING  
**Dependencies:** TASK-021

Version 1 is complete only after the definition of done in `agent-plan.md` is reviewed and this gate is set to `DONE` by a human.

