; Minimal SafeCall implementation — catches thrown values and reports unexpected errors
#Include <Core\ErrorRecord>
#Include <Core\ErrorReporter>

; SafeCall(operationId, callable, context?, args?) => Object
; Usage: result := SafeCall(operationId, Func, context?, ArgsArray?)
; Returns an object: { status: "success" | "cancelled" | "validation-failed" | "execution-failed", value: ..., errorRecord: ... }
SafeCall(operationId, callable, context := unset, args := unset) {
    start := A_TickCount
    if (IsSet(context) = false || context = unset)
    context := {}
    if (IsSet(args) = false || args = unset)
        args := []
    try {
        ; Support both function references and bound-callable closures
        try {
            value := callable(args*)
        } catch inner {
            try {
                value := callable.Call(args*)
            } catch {
                throw inner
            }
        }

        duration := A_TickCount - start
        return { status: "success", value: value, durationMs: duration }
    } catch _ex {
        duration := A_TickCount - start
        ; Determine if this is an expected outcome — heuristic: special error types or messages
        ; For now treat everything as unexpected execution-failed; classification refinement later
        rec := ErrorRecord.FromThrown(_ex, { serviceId: (context.serviceId != unset ? context.serviceId : ""), operationId: operationId, category: "invocation", severity: "error", durationMs: duration, safeMessage: "Unexpected error in operation" })
        ErrorReporter.Report(rec)
        return { status: "execution-failed", errorRecord: rec, durationMs: duration }
    }
}
