; ============================================================================
; Control Deck - Client API for the suite's control centre
; ============================================================================
;
; [FEATURES]
;   - Overview, Processes, Logs, Tests, Profiles, and Health sections in one
;     WebView2 window, hosted by Dashboard.ahk
;   - The host starts hidden with the suite; these functions show, hide, or
;     start it from any other script and open it on a chosen section
;
; [USAGE]
;   - ShowControlDeck(section?) / HideControlDeck()
;   - Opened from the tray menu's "Control Deck" item, the Macro Board, the
;     Age of Efficiency command D (or AL), or a Logger notification (on Logs)
; ============================================================================

#Include ..\..\Lib\Core\OnError.ahk
#Include ..\..\Lib\Core\Paths.ahk
#Include Controller.ahk

ShowControlDeck(section := "overview") {
	dashboardWindow := FindControlDeckWindow()
	if !dashboardWindow {
		StartControlDeck()
		dashboardWindow := WaitForControlDeckWindow()
	}
	if dashboardWindow {
		WinShow("ahk_id " dashboardWindow)
		WinActivate("ahk_id " dashboardWindow)
		RequestControlDeckSection(dashboardWindow, section)
	}
}

RequestControlDeckSection(dashboardWindow, section) {
	sectionIds := Map("overview", 1, "processes", 2, "logs", 3, "tests", 4, "profiles", 5, "health", 6)
	if sectionIds.Has(section)
		PostMessage(0x8001, sectionIds[section], 0, , "ahk_id " dashboardWindow)
}

HideControlDeck() {
	if dashboardWindow := FindControlDeckWindow()
		try WinHide("ahk_id " dashboardWindow)
}

FindControlDeckWindow() {
	hiddenWindowsWereDetected := A_DetectHiddenWindows
	previousTitleMatchMode := A_TitleMatchMode
	DetectHiddenWindows(true)
	SetTitleMatchMode(3)
	dashboardWindow := WinExist(ControlDeck.WIN_TITLE)
	SetTitleMatchMode(previousTitleMatchMode)
	DetectHiddenWindows(hiddenWindowsWereDetected)
	return dashboardWindow
}

StartControlDeck() {
	dashboardScript := Paths.dashboards "\Control Deck\Dashboard.ahk"
	Run('"' A_AhkPath '" "' dashboardScript '"')
}

; A generous timeout - WebView2 first-run init (extracting the loader, spinning
; up its child process) can take several seconds on a cold/slow machine.
WaitForControlDeckWindow(timeoutMs := 20000) {
	startedAt := A_TickCount
	while (A_TickCount - startedAt < timeoutMs) {
		if dashboardWindow := FindControlDeckWindow()
			return dashboardWindow
		Sleep(25)
	}
	return 0
}
