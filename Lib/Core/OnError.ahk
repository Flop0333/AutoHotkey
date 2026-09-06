#Include ..\Extensions\Json.ahk
#Include Paths.ahk

OnError(HandleUnhandledError)

HandleUnhandledError(error, mode) {
    try LogAndNotifyError(error.Message, error.HasProp("Stack") ? error.Stack : "")
    return true ; Suppress the default modal error dialog; the failed thread ends.
}

ErrorLogDirectory() => EnvGet("AUTOHOTKEY_LOG_DIR") != "" ? EnvGet("AUTOHOTKEY_LOG_DIR") : Paths.autohotkey "\Logs"
ErrorLogFile() => ErrorLogDirectory() "\errors.log"
ErrorLogReadStateFile() => ErrorLogDirectory() "\errors.read"

GetLogEntryCount() {
	return ReadLogEntries().Length
}

ReadLogEntries() {
	entries := []
	if !FileExist(ErrorLogFile())
		return entries
	for line in StrSplit(FileRead(ErrorLogFile(), "UTF-8"), "`n", "`r") {
		if (Trim(line) = "")
			continue
		try {
			entry := JSON.parse(line)
			if (entry is Map && entry.Has("severity") && entry.Has("message"))
				entries.Push(entry)
		}
	}
	return entries
}

GetReadLogEntryCount() {
    if !FileExist(ErrorLogReadStateFile())
        return 0
    try return Max(0, Integer(Trim(FileRead(ErrorLogReadStateFile(), "UTF-8"))))
    return 0
}

MarkAllLogsRead() {
	DirCreate(ErrorLogDirectory())
    readState := FileOpen(ErrorLogReadStateFile(), "w", "UTF-8")
    readState.Write(GetLogEntryCount())
	readState.Close()
}

GetUnreadLogEntries() {
	entries := ReadLogEntries()
	readEntryCount := Min(GetReadLogEntryCount(), entries.Length)
	unreadEntries := []
	loop entries.Length - readEntryCount
		unreadEntries.Push(entries[readEntryCount + A_Index])
	return unreadEntries
}

GetUnreadLogCounts() {
	counts := Map("info", 0, "warning", 0, "error", 0)
	for entry in GetUnreadLogEntries() {
		severity := entry.Has("severity") ? entry["severity"] : "info"
		if counts.Has(severity)
			counts[severity] += 1
	}
	return counts
}

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
	DirCreate(ErrorLogDirectory())
    FileAppend(JSON.Dump(entry) "`n", ErrorLogFile(), "UTF-8")
}

; Called once per full-suite start (see RunStartup) so the dashboard only ever
; shows errors from the current run, not accumulated history from past runs.
ClearErrorLog() {
    if FileExist(ErrorLogFile())
        FileDelete(ErrorLogFile())
    if FileExist(ErrorLogReadStateFile())
        FileDelete(ErrorLogReadStateFile())
}
