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

		; This test is intermittently flaky on CI at the assertions just below
		; (both the visibility check and the unread-count check have each
		; failed on separate runs), consistent with something occasionally
		; logging a stray LogAndNotify* entry during host startup that this
		; test didn't cause. The exact source isn't confirmed - nothing in
		; the Logger/Dashboard hosts' own include chain (Core.ahk -> Secrets
		; Service.ahk) calls Secret.Get() eagerly, so "missing-secret
		; notices" (the original suspicion) doesn't hold up under inspection;
		; a transient WebView2/COM hiccup during first-run init, caught by
		; the global OnError handler and logged as a notifying error, is
		; another candidate. It reproduces on CI but not locally after
		; several attempts, which points at something timing/environment-
		; specific rather than a logic bug in LogInfo/Controller.ahk (traced
		; through both - the notify gating there is correct).
		;
		; Whatever the source, clearing the log doesn't retroactively hide a
		; popup a stray notify already made visible - that only happens once
		; the Logger's own independent poll loop notices the clear and
		; reacts (see _Poll's GetReadLogEntryCount() >= entries.Length
		; check), which takes up to its own 1000ms tick, not however long we
		; guess we'd need to wait beforehand. So actively wait for that
		; settle to actually happen (an instant no-op if nothing stray
		; fired) instead of assuming a fixed delay covers it.
		Assert.True(WaitUntil(() => !IsVisible(FindLoggerWindow())), "Logger should settle back to hidden after any incidental startup logging")
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
