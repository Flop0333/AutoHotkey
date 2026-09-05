#Include ..\Tools\Info.ahk
#Include ..\Extensions\Json.ahk
#Include Paths.ahk

OnError(HandleUnhandledError)

HandleUnhandledError(error, mode) {
    try Info("Unhandled error: " error.Message "`n" error.Stack, 4000)
    try LogError(error)
    return true ; Suppress the default modal error dialog; the failed thread ends.
}

; Appends a structured entry (JSON lines format) to the shared error log,
; so past errors stay reviewable instead of only flashing in a toast.
LogError(error, severity := "error") {
    entry := Map(
        "timestamp", FormatTime(, "yyyy-MM-dd HH:mm:ss"),
        "script", A_ScriptName,
        "severity", severity,
        "message", error.Message,
        "stack", error.HasProp("Stack") ? error.Stack : ""
    )
    logDir := Paths.autohotkey "\Logs"
    DirCreate(logDir)
    FileAppend(JSON.Dump(entry) "`n", logDir "\errors.log", "UTF-8")
}
