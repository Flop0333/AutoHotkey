#Include ..\Extensions\Json.ahk
#Include Paths.ahk

OnError(HandleUnhandledError)

HandleUnhandledError(error, mode) {
    try {
        LogAndNotifyError(error.Message, error.HasProp("Stack") ? error.Stack : "")
        return true ; Suppress the default dialog only after persistence succeeds.
    }
    return false ; Preserve AutoHotkey's fallback when the logging path itself fails.
}

ErrorLogDirectory() => EnvGet("AUTOHOTKEY_LOG_DIR") != "" ? EnvGet("AUTOHOTKEY_LOG_DIR") : Paths.autohotkey "\Logs"
ErrorLogFile() => ErrorLogDirectory() "\errors.log"
ErrorLogReadStateFile() => ErrorLogDirectory() "\errors.read"
ErrorLogSessionStateFile() => ErrorLogDirectory() "\errors.session"
ErrorLogArchiveDirectory() => ErrorLogDirectory() "\Archive"

; Every AHK process writes the same two files. A named mutex keeps append,
; read-cursor updates, and session reset/rotation atomic across processes.
LoggingMutexName() => "Local\AutoHotkeySuite.StructuredLogging"

WithLoggingLock(callback, timeoutMs := 15000) {
	mutex := DllCall("CreateMutexW", "Ptr", 0, "Int", false, "Str", LoggingMutexName(), "Ptr")
	if !mutex
		throw OSError()
	waitResult := DllCall("WaitForSingleObject", "Ptr", mutex, "UInt", timeoutMs, "UInt")
	if (waitResult != 0 && waitResult != 0x80) {
		DllCall("CloseHandle", "Ptr", mutex)
		if (waitResult = 0x102)
			throw Error("Timed out waiting for the shared logging lock")
		throw OSError()
	}
	try return callback.Call()
	finally {
		DllCall("ReleaseMutex", "Ptr", mutex)
		DllCall("CloseHandle", "Ptr", mutex)
	}
}

GetLogEntryCount() {
	return ReadLogEntries().Length
}

ReadLogEntries() {
	return WithLoggingLock(() => _ReadLogEntriesFromFileLocked(ErrorLogFile()))
}

ReadLogEntriesFromFile(logFile) {
	return WithLoggingLock(() => _ReadLogEntriesFromFileLocked(logFile))
}

; Caller must hold the logging mutex so rotation cannot move the file between
; the existence check and the read.
_ReadLogEntriesFromFileLocked(logFile) {
	entries := []
	if !FileExist(logFile)
		return entries
	for line in StrSplit(FileRead(logFile, "UTF-8"), "`n", "`r") {
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
	return WithLoggingLock(() => _GetReadLogEntryCountLocked())
}

_GetReadLogEntryCountLocked() {
    if !FileExist(ErrorLogReadStateFile())
        return 0
    try return Max(0, Integer(Trim(FileRead(ErrorLogReadStateFile(), "UTF-8"))))
    return 0
}

MarkAllLogsRead() {
	WithLoggingLock(() => _MarkAllLogsReadLocked())
}

GetLogSessionId() {
	return WithLoggingLock(() => _GetLogSessionIdLocked())
}

_GetLogSessionIdLocked() {
	if !FileExist(ErrorLogSessionStateFile())
		return ""
	try return Trim(FileRead(ErrorLogSessionStateFile(), "UTF-8"))
	return ""
}

; Return one consistent view for consumers that need entries, the read cursor,
; and the session identity together.
ReadLogState() {
	return WithLoggingLock(() => Map(
		"entries", _ReadLogEntriesFromFileLocked(ErrorLogFile()),
		"readEntryCount", _GetReadLogEntryCountLocked(),
		"sessionId", _GetLogSessionIdLocked()
	))
}

_MarkAllLogsReadLocked() {
	DirCreate(ErrorLogDirectory())
	readState := FileOpen(ErrorLogReadStateFile(), "w", "UTF-8")
	try readState.Write(_ReadLogEntriesFromFileLocked(ErrorLogFile()).Length)
	finally readState.Close()
}

GetUnreadLogEntries(entries?, readEntryCount?) {
	if !IsSet(entries) {
		state := ReadLogState()
		entries := state["entries"]
		readEntryCount := state["readEntryCount"]
	} else if !IsSet(readEntryCount) {
		readEntryCount := GetReadLogEntryCount()
	}
	readEntryCount := Min(readEntryCount, entries.Length)
	unreadEntries := []
	loop entries.Length - readEntryCount
		unreadEntries.Push(entries[readEntryCount + A_Index])
	return unreadEntries
}

GetUnreadLogCounts(entries?, readEntryCount?) {
	counts := Map("info", 0, "warning", 0, "error", 0)
	if IsSet(entries)
		unreadEntries := IsSet(readEntryCount) ? GetUnreadLogEntries(entries, readEntryCount) : GetUnreadLogEntries(entries)
	else
		unreadEntries := GetUnreadLogEntries()
	for entry in unreadEntries {
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
	if !(stack is String)
		throw TypeError("Log entry stack must be a string", -1, Type(stack))
    entry := Map(
        "timestamp", FormatTime(, "yyyy-MM-dd HH:mm:ss"),
        "script", A_ScriptName,
        "severity", severity,
        "message", message,
        "stack", stack,
        "notify", notify
    )
	serializedEntry := JSON.Dump(entry) "`n"
	WithLoggingLock(() => _AppendLogEntryLocked(serializedEntry))
}

_AppendLogEntryLocked(serializedEntry) {
	DirCreate(ErrorLogDirectory())
	FileAppend(serializedEntry, ErrorLogFile(), "UTF-8")
}

; Test/reset helper. Full-suite startup uses StartNewLogSession() so history is
; archived instead of discarded.
ClearErrorLog() {
	WithLoggingLock(() => _ClearErrorLogLocked())
}

_ClearErrorLogLocked() {
	DirCreate(ErrorLogDirectory())
    if FileExist(ErrorLogFile())
        FileDelete(ErrorLogFile())
    if FileExist(ErrorLogReadStateFile())
        FileDelete(ErrorLogReadStateFile())
	_WriteNewLogSessionIdLocked()
}

StartNewLogSession(maxArchives := 10) {
	WithLoggingLock(() => _StartNewLogSessionLocked(maxArchives))
}

_StartNewLogSessionLocked(maxArchives) {
	DirCreate(ErrorLogDirectory())
	if (FileExist(ErrorLogFile()) && FileGetSize(ErrorLogFile()) > 0) {
		DirCreate(ErrorLogArchiveDirectory())
		baseName := ErrorLogArchiveDirectory() "\errors-" FormatTime(, "yyyyMMdd-HHmmss")
		archiveIndex := 0
		loop files baseName "-*.log", "F" {
			if RegExMatch(A_LoopFileName, "-(\d+)\.log$", &match)
				archiveIndex := Max(archiveIndex, Integer(match[1]))
		}
		archivePath := baseName "-" Format("{:03}", archiveIndex + 1) ".log"
		FileMove(ErrorLogFile(), archivePath)
	}
	if FileExist(ErrorLogReadStateFile())
		FileDelete(ErrorLogReadStateFile())
	_WriteNewLogSessionIdLocked()
	_PruneLogArchivesLocked(maxArchives)
}

_WriteNewLogSessionIdLocked() {
	static sequence := 0
	sequence++
	sessionId := FormatTime(, "yyyyMMdd-HHmmss") "-" DllCall("GetCurrentProcessId") "-" A_TickCount "-" sequence
	stateFile := FileOpen(ErrorLogSessionStateFile(), "w", "UTF-8")
	try stateFile.Write(sessionId)
	finally stateFile.Close()
	return sessionId
}

_PruneLogArchivesLocked(maxArchives) {
	if !DirExist(ErrorLogArchiveDirectory())
		return
	archiveList := ""
	loop files ErrorLogArchiveDirectory() "\errors-*.log", "F"
		archiveList .= A_LoopFileFullPath "`n"
	if !archiveList
		return
	archives := StrSplit(RTrim(Sort(archiveList), "`n"), "`n")
	deleteCount := Max(0, archives.Length - Max(0, maxArchives))
	loop deleteCount
		FileDelete(archives[A_Index])
}
