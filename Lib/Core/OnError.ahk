#Include ..\Extensions\Json.ahk
#Include Paths.ahk

OnError(HandleUnhandledError)
OnMessage(0x404, HandleTrayIconMessage) ; AHK_NOTIFYICON: catches clicks on the error TrayTip

HandleUnhandledError(error, mode) {
    try LogAndNotifyError(error.Message, error.HasProp("Stack") ? error.Stack : "")
    return true ; Suppress the default modal error dialog; the failed thread ends.
}

; lParam 0x405 (NIN_BALLOONUSERCLICK) means the user clicked the TrayTip balloon.
HandleTrayIconMessage(wParam, lParam, msg, hwnd) {
    if (lParam = 0x405)
        OpenLogDashboard()
}

OpenLogDashboard() {
    Run(Paths.dashboards '\Log Dashboard\Log Dashboard.ahk')
}

ErrorLogFile() => Paths.autohotkey "\Logs\errors.log"

; --- Log only: append a structured entry, no notification. ---------------
LogInfo(message) => AppendLogEntry("info", message)
LogWarning(message) => AppendLogEntry("warning", message)
LogError(message, stack := "") => AppendLogEntry("error", message, stack)

; --- Log and notify: append the entry, then surface it immediately. ------
LogAndNotifyInfo(message) {
    LogInfo(message)
    Notify("info", message)
}

LogAndNotifyWarning(message) {
    LogWarning(message)
    Notify("warning", message)
}

LogAndNotifyError(message, stack := "") {
    LogError(message, stack)
    Notify("error", message)
}

; Placeholder notification (native TrayTip) until the custom Logger popup replaces it.
Notify(severity, message) {
    icons := Map("info", 0x1, "warning", 0x2, "error", 0x3)
    try TrayTip(message, "AutoHotkey " StrTitle(severity), icons.Get(severity, 0x1))
}

; Appends a structured entry (JSON lines format) to the shared error log,
; so past errors stay reviewable instead of only flashing in a toast.
AppendLogEntry(severity, message, stack := "") {
    entry := Map(
        "timestamp", FormatTime(, "yyyy-MM-dd HH:mm:ss"),
        "script", A_ScriptName,
        "severity", severity,
        "message", message,
        "stack", stack
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
