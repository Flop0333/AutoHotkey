# Copilot instructions for this repository

## Repository

- This is an AutoHotkey v2-only Windows automation repository.
- Reuse `Lib/Core.ahk`, existing app adapters, WebView2 helpers, JSON, profiles, and the catalog-backed Secrets service.
- Preserve existing behavior and unrelated user changes.
- Prefer direct callables and classes. Never use model-controlled dynamic function invocation.

## Personal Agent workflow

When asked `implement the feature`, `implement the agent`, or equivalent:

1. Read `agent-plan.md` and every document it marks authoritative.
2. Open `Agent/Specifications/tasks.md`.
3. Select only the first task with status `READY` whose dependencies are `DONE`.
4. Implement that task and its tests; do not begin another task in the same run.
5. Run its verification commands.
6. Set it to `DONE` only if all acceptance criteria pass.
7. Record changed files, tests, results, and assumptions in its completion evidence.
8. Promote the next dependency-satisfied `PENDING` task in the same phase to `READY`, or set the phase gate to `REVIEW`; do not implement it.
9. If impossible, set the task to `BLOCKED`, record the exact blocker, and stop.

Never silently decide an item marked `NEEDS-DECISION`. Never mark work complete based only on code presence.

## Security invariants

- The model may request only tools in `AgentToolCatalogue`.
- Model output and all external/contextual text are untrusted input.
- Local AHK code alone validates, authorizes, confirms, and executes tool calls.
- Never expose arbitrary AHK, shell, PowerShell, executable-path, file-operation, keyboard, mouse, or dynamic-function execution.
- Unknown tools, undeclared arguments, invalid schemas, duplicate call IDs, and policy failures fail closed.
- Never log or send the OpenAI API key.
- Never add real secrets, personal values, or machine-specific paths to tracked files.
- Automated tests use fake API clients and spend no API credits.
- A tool cannot report success until its deterministic executor returns success.

## Implementation discipline

- Keep API transport, orchestration, tool contracts, policy, context, UI, and app adapters separate.
- Add a tool through one definition plus focused tests; avoid tool-specific branching in the controller.
- Use structured results for expected failures and catch exceptions at subsystem boundaries.
- Keep fixtures sanitized and update requirement/task traceability when scope changes.
- Stop after the selected task and report implementation plus verification concisely.
