; ============================================================================
; Control Dashboard - Manages the running suite and reviews its log entries
; ============================================================================
;
; [FEATURES]
;   - List view of Logs\errors.log with filtering/sorting by severity, script, time
;   - Detail view showing the full message and stack trace for a selected entry
;   - Web-based frontend using WebView2
;
; [USAGE]
;   - Opened via the tray menu's "Control Dashboard" item, or by clicking an
;     error TrayTip
; ============================================================================

#Include ..\..\Lib\Core\OnError.ahk
#Include ..\..\Lib\Core\Paths.ahk
#Include Controller.ahk

ShowControlDashboard(section := "overview") {
	dashboardWindow := FindControlDashboardWindow()
	if !dashboardWindow {
		StartControlDashboard()
		dashboardWindow := WaitForControlDashboardWindow()
	}
	if dashboardWindow {
		WinShow("ahk_id " dashboardWindow)
		WinActivate("ahk_id " dashboardWindow)
		MarkAllLogsRead()
		RequestControlDashboardSection(dashboardWindow, section)
	}
}

RequestControlDashboardSection(dashboardWindow, section) {
	sectionIds := Map("overview", 1, "processes", 2, "logs", 3, "tests", 4, "profiles", 5, "health", 6)
	if sectionIds.Has(section)
		PostMessage(0x8001, sectionIds[section], 0, , "ahk_id " dashboardWindow)
}

HideControlDashboard() {
	if dashboardWindow := FindControlDashboardWindow()
		try WinHide("ahk_id " dashboardWindow)
}

FindControlDashboardWindow() {
	hiddenWindowsWereDetected := A_DetectHiddenWindows
	previousTitleMatchMode := A_TitleMatchMode
	DetectHiddenWindows(true)
	SetTitleMatchMode(3)
	dashboardWindow := WinExist(ControlDashboard.WIN_TITLE)
	SetTitleMatchMode(previousTitleMatchMode)
	DetectHiddenWindows(hiddenWindowsWereDetected)
	return dashboardWindow
}

StartControlDashboard() {
	dashboardScript := Paths.dashboards "\Control Dashboard\Dashboard.ahk"
	Run('"' A_AhkPath '" "' dashboardScript '"')
}

; A generous timeout - WebView2 first-run init (extracting the loader, spinning
; up its child process) can take several seconds on a cold/slow machine.
WaitForControlDashboardWindow(timeoutMs := 20000) {
	startedAt := A_TickCount
	while (A_TickCount - startedAt < timeoutMs) {
		if dashboardWindow := FindControlDashboardWindow()
			return dashboardWindow
		Sleep(25)
	}
	return 0
}
