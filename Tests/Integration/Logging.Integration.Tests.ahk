#Requires AutoHotkey v2

; The logger/dashboard hosts spend most of their life hidden by design, and
; WinGetPID (unlike FindLoggerWindow/FindLogDashboardWindow, which toggle this
; locally) needs this on to operate on them via ahk_id.
DetectHiddenWindows(true)

IsVisible(hwnd) => hwnd && DllCall("IsWindowVisible", "Ptr", hwnd)

WaitUntil(predicate, timeoutMs := 4000) {
	startedAt := A_TickCount
	while (A_TickCount - startedAt < timeoutMs) {
		if predicate.Call()
			return true
		Sleep(50)
	}
	return false
}

; Waits for GetLogEntryCount() to stop changing for quietMs, instead of
; assuming any single checkpoint (a fixed sleep, or "is the popup hidden
; right now") is late enough to have seen everything. Confirmed necessary,
; not just defensive: Profiles.work's static initializer
; (Profiles/Profile Manager.ahk) eagerly calls Secrets.WorkDeviceNames.Get(),
; which calls SecretsFileManager.Initialize() - and that acquires a
; cross-process named mutex shared by every AHK process on the machine,
; doing a full first-time sync of My Secrets.json while holding it (empty/
; nonexistent on a fresh CI checkout, so every catalog entry needs writing).
; Since both the Logger and Dashboard hosts call this independently at
; startup, whichever one loses that mutex race can be delayed by however
; long the winner's first-time sync takes - which is why this warning was
; still observed arriving *after* both of this file's two previous fixes
; (a fixed sleep, then "wait until already hidden") had already moved on.
; Waiting for quiet, not a fixed point, absorbs that delay whatever it is.
WaitForLogQuiescence(quietMs := 1200, timeoutMs := 8000) {
	startedAt := A_TickCount
	lastCount := -1
	lastChangeAt := A_TickCount
	while (A_TickCount - startedAt < timeoutMs) {
		count := GetLogEntryCount()
		if (count != lastCount) {
			lastCount := count
			lastChangeAt := A_TickCount
		} else if (A_TickCount - lastChangeAt >= quietMs) {
			return true
		}
		Sleep(100)
	}
	return false
}

; Diagnostic only, for the two assertions below that have actually failed on
; CI (in different combinations across different runs) despite two attempted
; fixes based on static analysis that didn't hold up. Rather than guess a
; third time, this surfaces the real log content - including which script
; wrote each entry - directly in the failure message on the next occurrence.
DumpEntries() {
	text := ""
	for entry in ReadLogEntries()
		text .= Format("`n  [{1}] script={2} notify={3} msg={4}",
			entry.Get("severity", "?"), entry.Get("script", "?"), entry.Get("notify", "?"), entry.Get("message", "?"))
	return text ? text : "`n  (no entries)"
}

Test_RealHostsAndCrossProcessBehavior() {
	if FindLoggerWindow() || FindLogDashboardWindow()
		return ; Never replace or close a developer's currently running hosts.

	loggerPid := 0
	dashboardPid := 0
	try {
		hosts := InitializeLogging()
		loggerPid := WinGetPID("ahk_id " hosts["logger"])
		dashboardPid := WinGetPID("ahk_id " hosts["dashboard"])
		Assert.NotEqual(loggerPid, dashboardPid, "Logger and dashboard must have separate host processes")
		Assert.False(IsVisible(hosts["logger"]), "Logger starts hidden")
		Assert.False(IsVisible(hosts["dashboard"]), "Dashboard starts hidden")

		; Confirmed via a diagnostic dump of the actual log on a real CI
		; failure: both hosts independently trigger a
		; "Secret not found: Work Device Names" LogAndNotify*Warning at
		; startup (Profiles.work's eager Secrets.WorkDeviceNames.Get() -
		; every real machine running this repo has that secret set, so it
		; never fires there, but a clean CI checkout never does). See
		; WaitForLogQuiescence's own comment for why this needs an active
		; wait for quiet rather than a single fixed checkpoint - on CI, this
		; warning can be delayed past both of this file's two earlier fixes
		; by mutex contention between the two hosts.
		Assert.True(WaitForLogQuiescence(), "Startup logging (e.g. the hosts' own missing-secret notices) should settle before this test's own log calls")

		; Quiescence alone still isn't enough: if that startup warning did
		; show the popup, ClearErrorLog() straight after doesn't hide it.
		; _Poll() only hides on GetReadLogEntryCount() >= entries.Length, and
		; going straight from clearing (entries.Length briefly 0) into this
		; test's own LogInfo() call below means the Logger's poll never
		; actually observes that "0 >= 0" moment - it only ever sees the
		; count back above 0 again (this test's own entry) once it does look,
		; so a popup shown by the earlier warning would otherwise never be
		; told it's safe to hide until that severity's own 5s timer expires,
		; long after this test's 1250ms wait. MarkAllLogsRead() first, then
		; actively waiting for the resulting hide, closes that gap: it
		; doesn't need the file to be empty, only for the read cursor to
		; catch up to whatever's already there.
		MarkAllLogsRead()
		Assert.True(WaitUntil(() => !IsVisible(FindLoggerWindow())), "Logger should hide once existing entries are marked read")
		ClearErrorLog()

		LogInfo("silent unread info")
		Sleep(1250)
		Assert.False(IsVisible(FindLoggerWindow()), "LogInfo increments unread state without notifying." DumpEntries())
		Assert.Equal(1, GetUnreadLogCounts()["info"], "Unexpected unread info count." DumpEntries())

		LogAndNotifyWarning("visible warning")
		Assert.True(WaitUntil(() => IsVisible(FindLoggerWindow())), "Notify log should show logger")
		Assert.Equal(1, GetUnreadLogCounts()["warning"])

		ShowLogDashboard()
		Assert.True(IsVisible(FindLogDashboardWindow()), "Client API should show shared dashboard")
		Assert.True(WaitUntil(() => !IsVisible(FindLoggerWindow())), "Opening dashboard should hide logger")
		Assert.Equal(0, GetUnreadLogEntries().Length, "Opening dashboard should mark all logs read")
		HideLogDashboard()
		Assert.False(IsVisible(FindLogDashboardWindow()), "Client API should hide shared dashboard")

		LogAndNotifyInfo("overlap info")
		Assert.True(WaitUntil(() => IsVisible(FindLoggerWindow())))
		Sleep(3000)
		LogAndNotifyError("overlap error")
		Sleep(2500)
		Assert.True(IsVisible(FindLoggerWindow()), "Logger stays open after first severity timer expires")
		Assert.True(WaitUntil(() => !IsVisible(FindLoggerWindow()), 4000), "Logger hides after final severity timer expires")
	} finally {
		if loggerPid && ProcessExist(loggerPid)
			ProcessClose(loggerPid)
		if dashboardPid && ProcessExist(dashboardPid)
			ProcessClose(dashboardPid)
	}
}

TestKit.Run("Real hosts, unread state, show/hide API, and overlapping timers", Test_RealHostsAndCrossProcessBehavior)
TestKit.Report()

#Include ..\Support\Assert.ahk
#Include ..\..\Dashboards\Logger\Logging.ahk
