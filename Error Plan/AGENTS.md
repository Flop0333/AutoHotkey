# Copilot workflow for Error Resilience

These instructions apply only to the Error Resilience project.

When asked to implement, continue, or work on the error plan:

1. Read `Error Plan/error-plan.md` and every authoritative document it links.
2. Open `Error Plan/tasks.md`.
3. Select only the first `READY` task whose dependencies are `DONE`.
4. Change it to `IN-PROGRESS` before editing production files.
5. Implement only that task and its requirement-linked tests.
6. Run the task's verification.
7. Set it to `DONE` only when every acceptance criterion passes, then record completion evidence.
8. Promote the next dependency-satisfied task in the same phase to `READY`, or set the phase gate to `REVIEW`; do not implement it.
9. If blocked, set it to `BLOCKED`, record the exact blocker, and stop.

Never silently resolve a `NEEDS-DECISION` item. Never mark a task complete from code presence alone. Preserve unrelated changes. Do not begin another task in the same run.

## Invariants

- AutoHotkey v2 only.
- Process isolation remains the primary service boundary.
- Runtime failures are contained at known invocation boundaries; `OnError` is only a fallback reporter.
- Load-time failures are prevented by validation before launch or replacement.
- Unexpected errors must be observable without blocking dialogs or sensitive data leakage.
- Never continue arbitrary execution after an unhandled error.
- Restarts are per-service, PID-specific, bounded, and never use `KillAllAHkProcesses()` automatically.
- Expected cancellation, validation, and unavailability are outcomes, not errors.
- This project does not depend on the removed Action Registry or on the Personal Agent project.

