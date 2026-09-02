#Requires AutoHotkey v2
#Include ErrorRecord.ahk
#Include ErrorReporter.ahk

/** Runs a failure-prone callable inside an error boundary. */
SafeCall(callable, context := unset, args := unset) {
    startedAt := A_TickCount
    if !IsSet(context)
        context := {}
    if !IsSet(args)
        args := []

    try {
        if !HasMethod(callable, "Call")
            throw TypeError("SafeCall expects a callable", -1)
        if !(args is Array)
            throw TypeError("SafeCall args must be an Array", -1)

        value := callable.Call(args*)
        return {status: "success", value: value, durationMs: A_TickCount - startedAt}
    } catch Any as executionError {
        duration := A_TickCount - startedAt
        serviceId := HasProp(context, "serviceId") ? context.serviceId : ""
        operationId := HasProp(context, "operationId") ? context.operationId : ""
        record := ErrorRecord.FromThrown(executionError, {
            serviceId: serviceId,
            operationId: operationId,
            category: "invocation",
            severity: "error",
            durationMs: duration,
            safeMessage: "Unexpected error in operation"
        })
        ErrorReporter.Report(record)
        return {status: "execution-failed", errorRecord: record, durationMs: duration}
    }
}
