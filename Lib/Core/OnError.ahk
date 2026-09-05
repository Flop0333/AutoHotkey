#Include ..\Extensions\Json.ahk
#Include Paths.ahk

OnError(HandleUnhandledError)
OnMessage(0x404, HandleTrayIconMessage) ; AHK_NOTIFYICON: catches clicks on the error TrayTip

HandleUnhandledError(error, mode) {
    try TrayTip("Unhandled error: " error.Message, "AutoHotkey Error", 0x3) ; 0x3 = error icon
    try LogError(error)
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
