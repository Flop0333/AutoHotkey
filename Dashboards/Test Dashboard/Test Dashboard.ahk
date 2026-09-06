; ============================================================================
; Test Dashboard - Runs the AutoHotkey test suites and reviews the results
; ============================================================================
;
; [FEATURES]
;   - "Run All Tests" button runs the syntax check, unit tests, and
;     integration tests in one pass (see Tests\Invoke-AllTests.ps1)
;   - Pass/fail history read from Logs\test-run-history.log
;   - Web-based frontend using WebView2
;
; [USAGE]
;   - Opened via the tray menu's "Test Dashboard" item
;   - Or run Tests\Run-Tests.ahk to kick off a run and open the dashboard in
;     one step
; ============================================================================

#Include ..\..\Lib\Core.ahk
#Include Controller.ahk

ShowTestDashboard() {
	dashboardWindow := FindTestDashboardWindow()
	if !dashboardWindow {
		StartTestDashboard()
		dashboardWindow := WaitForTestDashboardWindow()
	}
	if dashboardWindow {
		WinShow("ahk_id " dashboardWindow)
		WinActivate("ahk_id " dashboardWindow)
	}
	return dashboardWindow
}

HideTestDashboard() {
	if dashboardWindow := FindTestDashboardWindow()
		try WinHide("ahk_id " dashboardWindow)
}

FindTestDashboardWindow() {
	hiddenWindowsWereDetected := A_DetectHiddenWindows
	previousTitleMatchMode := A_TitleMatchMode
	DetectHiddenWindows(true)
	SetTitleMatchMode(3)
	dashboardWindow := WinExist(TestDashboard.WIN_TITLE)
	SetTitleMatchMode(previousTitleMatchMode)
	DetectHiddenWindows(hiddenWindowsWereDetected)
	return dashboardWindow
}

StartTestDashboard() {
	dashboardScript := Paths.dashboards "\Test Dashboard\Dashboard.ahk"
	Run('"' A_AhkPath '" "' dashboardScript '"')
}

; Shared by the Apps.json "Test" command (see Command Methods.ahk) and the
; tray menu's "Run Tests" item - opens the dashboard and kicks off a run.
RunTests() {
	ShowTestDashboard()
	Run('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' TestDashboard.RUNNER_SCRIPT '"', , "Hide")
}

; A generous timeout - WebView2 first-run init (extracting the loader, spinning
; up its child process) can take several seconds on a cold/slow machine.
WaitForTestDashboardWindow(timeoutMs := 20000) {
	startedAt := A_TickCount
	while (A_TickCount - startedAt < timeoutMs) {
		if dashboardWindow := FindTestDashboardWindow()
			return dashboardWindow
		Sleep(25)
	}
	return 0
}
