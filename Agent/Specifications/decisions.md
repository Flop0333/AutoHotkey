# Accepted Architecture Decisions

Changing one requires updating dependent requirements and tasks.

## DEC-001 — API and model

Use the OpenAI Responses API with custom function tools. Keep the model ID configurable. Start with `gpt-5.4-mini`, subject only to availability verification during the manual live smoke test.

## DEC-002 — HTTP

Wrap the existing `WinHttpRequest` behind `OpenAIResponsesClient`; add no Node or .NET runtime in version 1.

## DEC-003 — State

Keep conversations in memory. Use Responses API continuation state internally; do not persist full conversations.

## DEC-004 — Tools

Use an agent-specific `AgentToolCatalogue`, not a general Action Registry. Expose only tools intentionally designed for model use.

## DEC-005 — Execution

Execute tools sequentially and disable parallel tool calls in version 1.

## DEC-006 — Confirmation

Read tools run without confirmation except sensitive context. Directly requested reversible tools may run immediately. Inferred reversible tools show a preview initially. Sensitive tools require confirmation or explicit opt-in. Destructive tools do not exist.

## DEC-007 — Schema subset

Support object, string, number, integer, boolean, array, required, enum, minimum, maximum, min/max length, min/max items, nested properties, and `additionalProperties: false`. Reject unsupported keywords during registration.

## DEC-008 — Tests

Create a small AHK v2 harness first: assertions, registration, fake dependencies, readable failures, and exit code 0/1. Normal automated tests are offline.

## DEC-009 — Audit

Write sanitized JSON-lines locally, rotate at 2 MiB, retain one previous file, and exclude full prompts/responses, context contents, and secrets.

## DEC-010 — Context

Show attachments before sending. Clipboard and selection default off each turn. Profile, safe device label, and active application metadata default on.

## DEC-011 — App identifiers

Allow only `vscode`, `notion`, `spotify`, `teams`, and `browser` in version 1 app tools. Map these locally to existing adapters.

## DEC-012 — Delivery

Implement one `READY` task per Copilot run. Mark it `DONE` only with recorded verification. Phase gates require human review.

