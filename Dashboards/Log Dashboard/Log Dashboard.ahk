; ============================================================================
; Log Dashboard - Reviews structured error/log entries written by OnError.ahk
; ============================================================================
;
; [FEATURES]
;   - List view of Logs\errors.log with filtering/sorting by severity, script, time
;   - Detail view showing the full message and stack trace for a selected entry
;   - Web-based frontend using WebView2
;
; [USAGE]
;   - Opened via the tray menu's "Log Dashboard" item, or by clicking an error TrayTip
; ============================================================================

#Include ..\..\Lib\Core.ahk
#Include Controller.ahk

ShowLogDashboard() {
	dashboardWindow := FindLogDashboardWindow()
	if !dashboardWindow {
		StartLogDashboard()
		dashboardWindow := WaitForLogDashboardWindow()
	}
	if dashboardWindow {
		WinShow("ahk_id " dashboardWindow)
		WinActivate("ahk_id " dashboardWindow)
	}
}

HideLogDashboard() {
	if dashboardWindow := FindLogDashboardWindow()
		WinHide("ahk_id " dashboardWindow)
}

FindLogDashboardWindow() {
	hiddenWindowsWereDetected := A_DetectHiddenWindows
	previousTitleMatchMode := A_TitleMatchMode
	DetectHiddenWindows(true)
	SetTitleMatchMode(3)
	dashboardWindow := WinExist(LogDashboard.WIN_TITLE)
	SetTitleMatchMode(previousTitleMatchMode)
	DetectHiddenWindows(hiddenWindowsWereDetected)
	return dashboardWindow
}

StartLogDashboard() {
	dashboardScript := Paths.dashboards "\Log Dashboard\Dashboard.ahk"
	Run('"' A_AhkPath '" "' dashboardScript '"')
}

WaitForLogDashboardWindow(timeoutMs := 5000) {
	startedAt := A_TickCount
	while (A_TickCount - startedAt < timeoutMs) {
		if dashboardWindow := FindLogDashboardWindow()
			return dashboardWindow
		Sleep(25)
	}
	return 0
}
