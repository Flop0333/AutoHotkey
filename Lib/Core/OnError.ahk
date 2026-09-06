#Include ..\Extensions\Json.ahk
#Include Paths.ahk

OnError(HandleUnhandledError)

HandleUnhandledError(error, mode) {
    try LogAndNotifyError(error.Message, error.HasProp("Stack") ? error.Stack : "")
    return true ; Suppress the default modal error dialog; the failed thread ends.
}

OpenLogDashboard() {
    Run(Paths.dashboards '\Log Dashboard\Log Dashboard.ahk')
}

ErrorLogFile() => Paths.autohotkey "\Logs\errors.log"

; --- Log only: append a structured entry. The Logger popup counts these ---
; --- toward the session totals but never pops up or expands for them. ----
LogInfo(message) => AppendLogEntry("info", message)
LogWarning(message) => AppendLogEntry("warning", message)
LogError(message, stack := "") => AppendLogEntry("error", message, stack)

; --- Log and notify: same entry, but flagged so the Logger popup treats --
; --- it as "new" - counted, shown as the latest, and worth popping up. --
LogAndNotifyInfo(message) => AppendLogEntry("info", message, , true)
LogAndNotifyWarning(message) => AppendLogEntry("warning", message, , true)
LogAndNotifyError(message, stack := "") => AppendLogEntry("error", message, stack, true)

; Appends a structured entry (JSON lines format) to the shared error log,
; so past errors stay reviewable instead of only flashing in a toast.
; `notify` marks entries the Logger popup should surface, not just count.
AppendLogEntry(severity, message, stack := "", notify := false) {
    entry := Map(
        "timestamp", FormatTime(, "yyyy-MM-dd HH:mm:ss"),
        "script", A_ScriptName,
        "severity", severity,
        "message", message,
        "stack", stack,
        "notify", notify
    )
    DirCreate(Paths.autohotkey "\Logs")
    FileAppend(JSON.Dump(entry) "`n", ErrorLogFile(), "UTF-8")
}

; Called once per full-suite start (see RunStartup) so the dashboard only ever
; shows errors from the current run, not accumulated history from past runs.
ClearErrorLog() {
    if FileExist(ErrorLogFile())
        FileDelete(ErrorLogFile())
}
