#Requires AutoHotkey v2
#Include ErrorReporter.ahk
#Include Notifier.ahk

/** Runs a failure-prone callable inside an error boundary. */
SafeCall(callable, message := "Something went wrong") {
    startedAt := A_TickCount

    try {
        if !HasMethod(callable, "Call")
            throw TypeError("SafeCall expects a callable", -1)

        value := callable.Call()
        return {status: "success", value: value, durationMs: A_TickCount - startedAt}
    } catch Any as executionError {
        duration := A_TickCount - startedAt
        record := ErrorReporter.Report(executionError, message).record
        Notifier.Error(message)
        return {status: "execution-failed", errorRecord: record, durationMs: duration}
    }
}

/** Returns a callback which applies SafeCall when AutoHotkey invokes it later. */
SafeCallback(callable, message := "Something went wrong") {
    return (callbackArgs*) => SafeCall((*) => callable.Call(callbackArgs*), message)
}
