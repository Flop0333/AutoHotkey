; ============================================================================
; Logger - Colored notification popup for logged info/warning/error entries
; ============================================================================
;
; [FEATURES]
;   - Polls Logs\errors.log for new entries (no cross-process messaging needed)
;   - Shows a small always-on-top popup 5 seconds after the last log entry
;   - Collapsed rows for info/warning/error with running counts; the row for
;     the latest not-yet-seen entry expands to show its script + message
;   - Left-click opens the Log Dashboard; right-click dismisses the popup
;     until the next log entry
; ============================================================================

#Include ..\..\Lib\Core.ahk
#Include Controller.ahk

ShowLogger() {
	loggerWindow := FindLoggerWindow()
	if !loggerWindow {
		StartLogger()
		loggerWindow := WaitForLoggerWindow()
	}
	if loggerWindow
		WinShow("ahk_id " loggerWindow)
}

HideLogger() {
	if loggerWindow := FindLoggerWindow()
		Try WinHide("ahk_id " loggerWindow)
}

FindLoggerWindow() {
	hiddenWindowsWereDetected := A_DetectHiddenWindows
	previousTitleMatchMode := A_TitleMatchMode
	DetectHiddenWindows(true)
	SetTitleMatchMode(3)
	loggerWindow := WinExist(LoggerPopup.WIN_TITLE)
	SetTitleMatchMode(previousTitleMatchMode)
	DetectHiddenWindows(hiddenWindowsWereDetected)
	return loggerWindow
}

StartLogger() => Run('"' A_AhkPath '" "' Paths.dashboards '\Logger\Logger Host.ahk"')

WaitForLoggerWindow(timeoutMs := 5000) {
	startedAt := A_TickCount
	while (A_TickCount - startedAt < timeoutMs) {
		if loggerWindow := FindLoggerWindow()
			return loggerWindow
		Sleep(25)
	}
	return 0
}
