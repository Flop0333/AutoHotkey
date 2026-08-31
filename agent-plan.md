# Personal Agent Operating System

## Purpose

Build a local Windows agent with a WebView2 conversation interface. An OpenAI model interprets requests and may propose a deliberately small set of typed tools. AutoHotkey remains the trusted Windows-native runtime that validates, authorizes, confirms, and executes those tools.

The model has no arbitrary access to AHK functions, shell, files, secrets, keyboard, mouse, or computer. Model output is untrusted input, not executable code.

## Authoritative specification

This project uses specification-driven development:

1. [Requirements](Agent/Specifications/requirements.md) — stable behavior and security IDs.
2. [Architecture](Agent/Specifications/architecture.md) — subsystem boundaries and contracts.
3. [Decisions](Agent/Specifications/decisions.md) — resolved version 1 choices.
4. [Test plan](Agent/Specifications/test-plan.md) — verification strategy.
5. [Execution ledger](Agent/Specifications/tasks.md) — task order and current state.
6. [.github/copilot-instructions.md](.github/copilot-instructions.md) — mandatory Copilot workflow.

When asked to **implement the feature**, Copilot reads these documents and implements exactly the first eligible `READY` task. It records verification evidence and stops. This prevents an unsafe, oversized attempt to build the whole product at once.

## Product flow

```text
User request
    ↓
WebView2 Agent UI
    ↓
Agent Controller attaches only visible, permitted context
    ↓
OpenAI Responses API receives instructions and eligible typed tools
    ↓
Model returns text and/or tool requests
    ↓
Local schema validation and policy
    ├─ deny
    ├─ request local confirmation
    └─ allow
          ↓
Exact registered AHK callable executes once
          ↓
Structured result returns to model and UI
          ↓
Final answer describes the actual outcome
```

## Version 1

### Conversation

- Multi-turn text conversation.
- Visible context attachments.
- Thinking, confirmation, execution, result, cancellation, and error states.
- Cancellation and bounded tool/API loops.
- Memory-only conversation state by default.

### Read tools

- Local time and active profile.
- Safe active-window and visible-window metadata.
- Allowlisted application status.
- Clipboard or selected text only after explicit opt-in.

### Reversible tools

- Launch or activate an allowlisted application.
- Activate, minimize, or maximize a selected visible window.
- Open a validated HTTP/HTTPS URL.
- Open this project in VS Code.
- Start the configured Spotify playlist.
- Start a timer between one minute and 24 hours.

Allowed application IDs are `vscode`, `notion`, `spotify`, `teams`, and `browser`. The model never supplies executable paths.

## Exclusions

Version 1 has no arbitrary AHK/dynamic function calls, shell, PowerShell, terminal, executable paths, arbitrary files, generated typing, pasting, mouse control, coordinate clicks, unrestricted UI Automation, password access, external messaging, purchases, deployments, shutdown, process killing, voice, schedules, autonomy, long-term memory, remote execution, automatic screenshots/OCR, or model-created tools.

Each deferred capability requires a separate specification and security review.

## API and secrets

Use the OpenAI Responses API with custom function tools. The model ID is configurable, initially `gpt-5.4-mini` subject to account availability during the live smoke test.

During implementation add:

```ahk
"OpenAIApiKey", Secret(
    "OpenAI API key",
    "Used by the Personal Agent to call the OpenAI Responses API"
)
```

Retrieve it only at request time:

```ahk
apiKey := Secrets.OpenAIApiKey.GetOrSet()
```

The value remains in Git-ignored `Secrets/My Secrets.json` and never enters prompts, conversation storage, fixtures, diagnostics, UI errors, or logs. Automated tests use a fake API and spend no credits.

## AgentTool contract

An `AgentTool` is an agent-specific allowlist entry, not a general Action Registry.

| Field | Meaning |
|---|---|
| `name` | Stable API-safe identifier |
| `title` | User-facing label |
| `description` | Exact model-selection guidance |
| `parameters` | Strict JSON schema |
| `execute` | Local callable, never sent to model |
| `risk` | `read`, `reversible`, `sensitive`, or `destructive` |
| `availability` | Local dependency check |
| `timeoutMs` | Execution bound |
| `redactedFields` | Values omitted from logs/history |

Only name, description, and parameter schema are transmitted. The catalogue never scans global functions and model strings never resolve dynamically to code.

## Safety invariants

- Unknown tools and invalid arguments fail closed.
- `additionalProperties` is false unless deliberately designed otherwise.
- URL, identifier, enum, number, array, and string limits are local.
- Tool-call IDs execute at most once.
- Sensitive operations require confirmation or explicit turn-level permission.
- Model text cannot grant confirmation.
- Clipboard, selection, windows, files, websites, and OCR are untrusted data.
- Model claims are not evidence of success; deterministic tool results are authoritative.
- API and tool errors cannot terminate the agent or wider suite.

## Risk levels

- **Read:** no state change; no confirmation except sensitive context.
- **Reversible:** easy-to-undo local change; direct requests may run, inferred operations preview initially.
- **Sensitive:** private context or meaningful external impact; requires permission or confirmation.
- **Destructive:** could delete, terminate work, alter security, or create account/financial impact; not registrable in version 1.

## Testing standard

The first task builds an offline AHK v2 test runner. Later work requires requirement-linked coverage for contracts, schemas, catalogue lookup, policy, confirmation, deduplication, API fixtures, orchestration, limits, cancellation, redaction, context privacy, prompt injection, tool adapters, UI states, and manual Windows behavior.

Production code without passing requirement-linked verification is incomplete.

## Definition of done

Version 1 is finished only when:

- [ ] Every requirement ID has automated or recorded manual evidence.
- [ ] Every task through `TASK-021` is `DONE`.
- [ ] All phase gates, including `GATE-004`, are human-approved and `DONE`.
- [ ] Responses API text and sequential typed tools work.
- [ ] The key uses the Secrets Catalog and ignored local JSON.
- [ ] Only registered AgentTools can execute.
- [ ] No arbitrary function, shell, executable, file, keyboard, mouse, or secret path exists.
- [ ] Arguments are locally schema-validated.
- [ ] Sensitive context/actions require local permission.
- [ ] Duplicate call IDs cannot duplicate side effects.
- [ ] Results distinguish all documented terminal states.
- [ ] Clipboard and selection are visibly opt-in.
- [ ] Secrets and sensitive content are absent from model context and audit logs.
- [ ] UI supports conversation, context, confirmation, progress, cancellation, and errors.
- [ ] Failures do not crash the agent or startup suite.
- [ ] Security and prompt-injection evaluations fail closed.
- [ ] Setup, privacy, limitations, cost boundary, and safe tool-authoring docs exist.
- [ ] Normal-use testing finds no unauthorized, duplicate, or falsely reported actions.

## Normal Copilot instruction

Once committed, the recurring instruction is simply:

> Implement the feature.

Repository instructions and the execution ledger determine the next task, verification, and stopping point.

## Official reference

- [OpenAI Responses API](https://developers.openai.com/api/reference/cli/resources/responses/methods/create)

