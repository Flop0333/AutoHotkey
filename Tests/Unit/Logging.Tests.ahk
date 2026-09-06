#Requires AutoHotkey v2

testRoot := A_Temp "\ahk-logging-tests-" A_TickCount "-" DllCall("GetCurrentProcessId")
DirCreate(testRoot)
EnvSet("AUTOHOTKEY_BASE", testRoot)

#Include ..\Support\Assert.ahk
#Include ..\..\Lib\Core\OnError.ahk

ResetLogFiles() => ClearErrorLog()

Test_AppendWritesStructuredEntry() {
	ResetLogFiles()
	LogInfo("hello")
	entries := ReadLogEntries()
	Assert.Equal(1, entries.Length)
	Assert.Equal("info", entries[1]["severity"])
	Assert.Equal("hello", entries[1]["message"])
	Assert.Equal(A_ScriptName, entries[1]["script"])
	Assert.False(entries[1]["notify"])
	Assert.True(entries[1].Has("timestamp"))
}

Test_NotifyVariantsSetNotifyFlag() {
	ResetLogFiles()
	LogAndNotifyInfo("i")
	LogAndNotifyWarning("w")
	LogAndNotifyError("e", "stack")
	entries := ReadLogEntries()
	Assert.Equal(3, entries.Length)
	for entry in entries
		Assert.True(entry["notify"])
	Assert.Equal("stack", entries[3]["stack"])
}

Test_UnreadCountsAllSeverities() {
	ResetLogFiles()
	LogInfo("i1")
	LogAndNotifyInfo("i2")
	LogWarning("w")
	LogError("e")
	counts := GetUnreadLogCounts()
	Assert.Equal(2, counts["info"])
	Assert.Equal(1, counts["warning"])
	Assert.Equal(1, counts["error"])
}

Test_MarkReadMovesCursorToCurrentEnd() {
	ResetLogFiles()
	LogInfo("before")
	LogWarning("before")
	MarkAllLogsRead()
	Assert.Equal(2, GetReadLogEntryCount())
	Assert.Equal(0, GetUnreadLogEntries().Length)
	LogAndNotifyError("after")
	unread := GetUnreadLogEntries()
	Assert.Equal(1, unread.Length)
	Assert.Equal("after", unread[1]["message"])
}

Test_MalformedLinesAreIgnoredConsistently() {
	ResetLogFiles()
	DirCreate(testRoot "\Logs")
	FileAppend("not json`n", ErrorLogFile(), "UTF-8")
	LogInfo("valid")
	Assert.Equal(1, GetLogEntryCount())
	MarkAllLogsRead()
	Assert.Equal(1, GetReadLogEntryCount())
	Assert.Equal(0, GetUnreadLogEntries().Length)
}

Test_InvalidReadStateFallsBackToZero() {
	ResetLogFiles()
	DirCreate(testRoot "\Logs")
	FileAppend("invalid", ErrorLogReadStateFile(), "UTF-8")
	Assert.Equal(0, GetReadLogEntryCount())
}

Test_ClearRemovesLogAndReadState() {
	ResetLogFiles()
	LogInfo("entry")
	MarkAllLogsRead()
	ClearErrorLog()
	Assert.False(FileExist(ErrorLogFile()))
	Assert.False(FileExist(ErrorLogReadStateFile()))
	Assert.Equal(0, GetUnreadLogEntries().Length)
}

Test_UnreadCountsIgnoreUnknownSeverities() {
	ResetLogFiles()
	AppendLogEntry("debug", "custom severity")
	LogInfo("known")
	counts := GetUnreadLogCounts()
	Assert.Equal(1, counts["info"])
	Assert.False(counts.Has("debug"))
}

Test_LogDirectoryEnvOverrideTakesPrecedence() {
	overrideDir := testRoot "\override-" A_TickCount
	EnvSet("AUTOHOTKEY_LOG_DIR", overrideDir)
	try {
		Assert.Equal(overrideDir "\errors.log", ErrorLogFile())
		LogInfo("in override dir")
		Assert.True(FileExist(overrideDir "\errors.log"))
	} finally {
		EnvSet("AUTOHOTKEY_LOG_DIR", "")
	}
}

; HandleUnhandledError is the function registered with OnError() - it's what
; actually turns an unhandled AHK error into a logged, notifying entry.
Test_HandleUnhandledErrorLogsNotifyingErrorAndSuppressesDialog() {
	ResetLogFiles()
	result := HandleUnhandledError(Error("boom"), "Return")
	Assert.True(result, "Must return true to suppress the default error dialog")
	entries := ReadLogEntries()
	Assert.Equal(1, entries.Length)
	Assert.Equal("error", entries[1]["severity"])
	Assert.Equal("boom", entries[1]["message"])
	Assert.True(entries[1]["notify"])
}

Test_HandleUnhandledErrorIncludesStackWhenPresent() {
	ResetLogFiles()
	err := Error("boom")
	err.Stack := "at foo()"
	HandleUnhandledError(err, "Return")
	Assert.Equal("at foo()", ReadLogEntries()[1]["stack"])
}

Test_HandleUnhandledErrorOmitsStackWhenAbsent() {
	; Error() auto-populates its own .Stack, so use a plain object to exercise
	; the HasProp("Stack") fallback for error-like values that don't have one.
	ResetLogFiles()
	HandleUnhandledError({ Message: "boom" }, "Return")
	Assert.Equal("", ReadLogEntries()[1]["stack"])
}

TestKit.Run("Append writes a structured non-notifying entry", Test_AppendWritesStructuredEntry)
TestKit.Run("LogAndNotify variants set notify and preserve stack", Test_NotifyVariantsSetNotifyFlag)
TestKit.Run("Unread counts include info, warning, and error logs", Test_UnreadCountsAllSeverities)
TestKit.Run("Opening/read action advances the cursor but leaves later entries unread", Test_MarkReadMovesCursorToCurrentEnd)
TestKit.Run("Malformed JSONL lines are ignored consistently", Test_MalformedLinesAreIgnoredConsistently)
TestKit.Run("Invalid read state safely falls back to zero", Test_InvalidReadStateFallsBackToZero)
TestKit.Run("Clearing a session removes logs and read state", Test_ClearRemovesLogAndReadState)
TestKit.Run("Unread counts silently ignore entries with unknown severities", Test_UnreadCountsIgnoreUnknownSeverities)
TestKit.Run("AUTOHOTKEY_LOG_DIR overrides the default log directory", Test_LogDirectoryEnvOverrideTakesPrecedence)
TestKit.Run("HandleUnhandledError logs a notifying error and suppresses the dialog", Test_HandleUnhandledErrorLogsNotifyingErrorAndSuppressesDialog)
TestKit.Run("HandleUnhandledError includes the error's stack when present", Test_HandleUnhandledErrorIncludesStackWhenPresent)
TestKit.Run("HandleUnhandledError omits the stack when absent", Test_HandleUnhandledErrorOmitsStackWhenAbsent)

TestKit.Report()
