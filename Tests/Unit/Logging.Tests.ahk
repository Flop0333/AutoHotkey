#Requires AutoHotkey v2

testRoot := A_Temp "\ahk-logging-tests-" A_TickCount "-" DllCall("GetCurrentProcessId")
DirCreate(testRoot)
EnvSet("AUTOHOTKEY_BASE", testRoot)

#Include ..\Support\Assert.ahk
#Include ..\..\Lib\Core\OnError.ahk

ResetLogFiles() => ClearErrorLog()

ClearLogArchivesForTest() {
	if !DirExist(ErrorLogArchiveDirectory())
		return
	loop files ErrorLogArchiveDirectory() "\*", "F"
		FileDelete(A_LoopFileFullPath)
}

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
	previousSessionId := GetLogSessionId()
	LogInfo("entry")
	MarkAllLogsRead()
	ClearErrorLog()
	Assert.False(FileExist(ErrorLogFile()))
	Assert.False(FileExist(ErrorLogReadStateFile()))
	Assert.Equal(0, GetUnreadLogEntries().Length)
	Assert.NotEqual(previousSessionId, GetLogSessionId(), "Clearing the log must start a distinct session")
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

Test_HandleUnhandledErrorFallsBackWhenPersistenceFails() {
	blockingFile := testRoot "\not-a-directory"
	FileAppend("block directory creation", blockingFile, "UTF-8")
	EnvSet("AUTOHOTKEY_LOG_DIR", blockingFile)
	try {
		Assert.False(HandleUnhandledError(Error("must remain visible"), "Return"),
			"Default AutoHotkey reporting must not be suppressed when logging fails")
	} finally {
		EnvSet("AUTOHOTKEY_LOG_DIR", "")
	}
}

Test_AppendRejectsNonStringStack() {
	ResetLogFiles()
	Assert.Throws(() => LogError("bad stack", Error("nested")), "A non-string stack must throw")
	Assert.Equal(0, GetLogEntryCount())
}

Test_StartNewSessionArchivesActiveLogAndResetsReadState() {
	ResetLogFiles()
	ClearLogArchivesForTest()
	previousSessionId := GetLogSessionId()
	LogInfo("previous session")
	MarkAllLogsRead()
	StartNewLogSession()
	Assert.False(FileExist(ErrorLogFile()))
	Assert.False(FileExist(ErrorLogReadStateFile()))
	archives := []
	loop files ErrorLogArchiveDirectory() "\errors-*.log", "F"
		archives.Push(A_LoopFileFullPath)
	Assert.Equal(1, archives.Length)
	Assert.True(InStr(FileRead(archives[1], "UTF-8"), "previous session") > 0)
	Assert.NotEqual(previousSessionId, GetLogSessionId(), "Rotating the log must start a distinct session")
}

Test_StartNewSessionAvoidsArchiveNameCollisions() {
	ResetLogFiles()
	ClearLogArchivesForTest()
	LogInfo("first")
	StartNewLogSession()
	LogInfo("second")
	StartNewLogSession()
	archiveCount := 0
	loop files ErrorLogArchiveDirectory() "\errors-*.log", "F"
		archiveCount++
	Assert.Equal(2, archiveCount)
}

Test_StartNewSessionPrunesOldestArchives() {
	ResetLogFiles()
	ClearLogArchivesForTest()
	loop 4 {
		LogInfo("session " A_Index)
		StartNewLogSession(2)
	}
	archives := []
	loop files ErrorLogArchiveDirectory() "\errors-*.log", "F"
		archives.Push(FileRead(A_LoopFileFullPath, "UTF-8"))
	Assert.Equal(2, archives.Length)
	combined := archives[1] archives[2]
	Assert.False(InStr(combined, "session 1") > 0)
	Assert.False(InStr(combined, "session 2") > 0)
	Assert.True(InStr(combined, "session 3") > 0)
	Assert.True(InStr(combined, "session 4") > 0)
}

Test_UnreadCountsCanUseOneEntriesSnapshot() {
	ResetLogFiles()
	LogInfo("in snapshot")
	snapshot := ReadLogEntries()
	LogWarning("after snapshot")
	counts := GetUnreadLogCounts(snapshot)
	Assert.Equal(1, counts["info"])
	Assert.Equal(0, counts["warning"])
	Assert.Equal(2, GetUnreadLogEntries().Length, "Default API still reads the latest file state")
}

Test_ReadLogStateReturnsOneConsistentSnapshot() {
	ResetLogFiles()
	LogInfo("read")
	MarkAllLogsRead()
	state := ReadLogState()
	Assert.Equal(1, state["entries"].Length)
	Assert.Equal(1, state["readEntryCount"])
	Assert.Equal(GetLogSessionId(), state["sessionId"])
}

Test_SharedParserValidatesArbitraryLogFile() {
	ResetLogFiles()
	fixture := testRoot "\parser-fixture.log"
	FileAppend("malformed`n", fixture, "UTF-8")
	FileAppend('{"severity":"warning","message":"valid"}`n', fixture, "UTF-8")
	entries := ReadLogEntriesFromFile(fixture)
	Assert.Equal(1, entries.Length)
	Assert.Equal("valid", entries[1]["message"])
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
TestKit.Run("HandleUnhandledError preserves default reporting when persistence fails", Test_HandleUnhandledErrorFallsBackWhenPersistenceFails)
TestKit.Run("Append rejects a non-string stack before persistence", Test_AppendRejectsNonStringStack)
TestKit.Run("New session archives the active log and resets read state", Test_StartNewSessionArchivesActiveLogAndResetsReadState)
TestKit.Run("Rapid session rotation avoids archive name collisions", Test_StartNewSessionAvoidsArchiveNameCollisions)
TestKit.Run("Session rotation prunes the oldest archives", Test_StartNewSessionPrunesOldestArchives)
TestKit.Run("Unread counts can reuse a single entries snapshot", Test_UnreadCountsCanUseOneEntriesSnapshot)
TestKit.Run("Log state returns entries, cursor, and session as one snapshot", Test_ReadLogStateReturnsOneConsistentSnapshot)
TestKit.Run("Shared parser validates an arbitrary JSONL log file", Test_SharedParserValidatesArbitraryLogFile)

TestKit.Report()
