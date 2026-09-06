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

		LogInfo("silent unread info")
		Sleep(1250)
		Assert.False(IsVisible(FindLoggerWindow()), "LogInfo increments unread state without notifying")
		Assert.Equal(1, GetUnreadLogCounts()["info"])

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
