# Personal Agent Requirements

Tasks and tests must reference these stable IDs.

## Product

- **REQ-PROD-001** — Multi-turn text conversation in a WebView2 UI.
- **REQ-PROD-002** — The model can request explicitly registered AHK tools and receive structured results.
- **REQ-PROD-003** — UI states cover thinking, confirmation, execution, success, cancellation, failure, and timeout.
- **REQ-PROD-004** — Cancelling a turn prevents all not-yet-started tool calls.
- **REQ-PROD-005** — API, parser, and tool failures do not crash the agent or broader suite.

## API

- **REQ-API-001** — Use `POST /v1/responses` and support text responses.
- **REQ-API-002** — Supply typed custom function tools generated from the local catalogue.
- **REQ-API-003** — Return function outputs with exact matching call IDs.
- **REQ-API-004** — Preserve required multi-turn continuation state.
- **REQ-API-005** — Parse all output items without assuming the first is assistant text.
- **REQ-API-006** — Convert authentication, connection, rate-limit, malformed-response, and timeout failures into sanitized errors.
- **REQ-API-007** — Limit a turn to five tool executions and eight API round trips.
- **REQ-API-008** — Disable parallel tool execution in version 1.

## Secrets and privacy

- **REQ-SEC-001** — Retrieve the key through `Secrets.OpenAIApiKey.GetOrSet()`.
- **REQ-SEC-002** — Store its value only in Git-ignored `Secrets/My Secrets.json`.
- **REQ-SEC-003** — Never expose the key or authorization header in prompts, UI, state, fixtures, or logs.
- **REQ-SEC-004** — Clipboard and selection require visible turn-level opt-in.
- **REQ-SEC-005** — Context not shown as attached is not transmitted.
- **REQ-SEC-006** — Context is labelled and treated as untrusted data.
- **REQ-SEC-007** — Audit logs exclude raw context, secrets, prompts, and sensitive arguments.

## Tools

- **REQ-TOOL-001** — Each tool has name, title, description, strict schema, callable, risk, availability, timeout, and redaction metadata.
- **REQ-TOOL-002** — Duplicate or invalid registrations fail startup validation.
- **REQ-TOOL-003** — Only exact registered names resolve to callables; no model-controlled dynamic invocation exists.
- **REQ-TOOL-004** — Arguments are validated locally before policy and execution.
- **REQ-TOOL-005** — Validation supports required fields, scalar types, enums, arrays, nested objects, length/range limits, and `additionalProperties: false`.
- **REQ-TOOL-006** — Unknown or malformed tools execute nothing.
- **REQ-TOOL-007** — Each call ID executes at most once.
- **REQ-TOOL-008** — Results use `success`, `cancelled`, `unavailable`, `invalid_arguments`, `denied`, `timeout`, or `failed`.
- **REQ-TOOL-009** — Deterministic tool results, not model claims, are authoritative.

## Policy

- **REQ-POL-001** — Policy checks registration, availability, profile, arguments, risk, limits, and confirmation.
- **REQ-POL-002** — Risks are `read`, `reversible`, `sensitive`, and `destructive`.
- **REQ-POL-003** — Sensitive tools need fresh confirmation or explicit turn-level permission.
- **REQ-POL-004** — Model text cannot grant or bypass confirmation.
- **REQ-POL-005** — Destructive tools are excluded from version 1.
- **REQ-POL-006** — Raw shell, PowerShell, arbitrary executables/files, generated typing, and coordinate clicks are excluded.
- **REQ-POL-007** — URL tools allow only `http`/`https`, enforce length limits, and reject embedded credentials.

## Context and initial tools

- **REQ-CTX-001** — Providers expose active profile, safe device label, active window, optional visible windows, optional selection, and optional clipboard.
- **REQ-CTX-002** — Providers declare sensitivity and permission requirements.
- **REQ-CTX-003** — Provider failure does not break unrelated features.
- **REQ-INIT-001** — Read tools cover local time, profile, active/visible windows, and allowlisted app status.
- **REQ-INIT-002** — Reversible tools cover allowlisted app launch/activation, window activation/minimize/maximize, validated URL opening, AutoHotkey project opening, configured Spotify playlist, and bounded timer.
- **REQ-INIT-003** — Clipboard and selection tools require opt-in.
- **REQ-INIT-004** — App identifiers are fixed enums; executable paths never come from the model.
- **REQ-INIT-005** — Timer duration is 1 minute through 24 hours.

## Operation

- **REQ-OPS-001** — Conversation state is memory-only by default.
- **REQ-OPS-002** — Audit events contain timestamp, local request ID, tool, policy, confirmation, status, duration, and sanitized category.
- **REQ-OPS-003** — Audit storage rotates at 2 MiB and retains one prior file.
- **REQ-OPS-004** — UI opens without an API call and remains responsive during work.
- **REQ-OPS-005** — Model, timeouts, and limits are non-secret configuration.

Voice, autonomy, remote execution, automatic screenshots, arbitrary files, password actions, external messaging, long-term memory, and model-created tools are deferred.

