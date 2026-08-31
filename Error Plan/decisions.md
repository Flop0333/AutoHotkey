# Accepted Error Resilience Decisions

## DEC-ERR-001 — Scope

AutoHotkey v2 production entrypoints launched by `Startup/Startup.ahk` are in scope. Third-party examples are excluded unless production code includes them.

## DEC-ERR-002 — Independence

This project does not use the removed Action Registry and does not depend on Personal Agent infrastructure. Expected operations use an error-specific `OperationResult` contract.

## DEC-ERR-003 — Isolation

Separate AHK processes remain the primary fault boundary. `SafeCall` contains known runtime invocation failures inside a service.

## DEC-ERR-004 — Global errors

`OnError` reports and suppresses the blocking default dialog but never asks AHK to continue arbitrary execution.

## DEC-ERR-005 — Load failures

Syntax/include/static initialization failures are addressed through `/Validate /ErrorStdOut` before launch or replacement, not runtime recovery.

## DEC-ERR-006 — Storage

Logs live under `%LocalAppData%\AutoHotkey Workflow\Logs`, use JSON Lines, rotate at 2 MiB, and retain five files.

## DEC-ERR-007 — Status transport

Use atomic per-service JSON status files under `%LocalAppData%\AutoHotkey Workflow\Runtime`. Each record includes PID and update time. Add heartbeats only for services where hung detection is valuable.

## DEC-ERR-008 — Restart defaults

Maximum three restarts in ten minutes with delays of 1, 5, then 20 seconds. Thirty healthy minutes reset the budget. Critical services may override only through validated manifest configuration.

## DEC-ERR-009 — Test strategy

Create an offline AHK v2 error-resilience test runner and isolated fixtures. Tests never modify real startup state or terminate unrelated AHK processes.

## DEC-ERR-010 — Delivery

Copilot implements one `READY` task per run. Phase gates require human approval. The service inventory is produced before manifest code.

