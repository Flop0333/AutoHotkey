; ============================================================================
; Logger - Colored notification popup for logged info/warning/error entries
; ============================================================================
;
; [FEATURES]
;   - Uses a lightweight native AHK GUI (no resident WebView2 process)
;   - Polls Logs\errors.log for new entries (no cross-process messaging needed)
;   - Shows notifying entries immediately, then hides 5 seconds after the latest
;   - Collapsed rows for info/warning/error with running counts; the row for
;     the latest not-yet-seen entry expands to show its script + message
;   - Left-click opens the Control Dashboard; right-click dismisses the popup
;     until the next log entry
; ============================================================================

#NoTrayIcon
#Include ..\..\Lib\Core\Paths.ahk
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

; Leave enough time for a cold machine or security scanner to start the host.
WaitForLoggerWindow(timeoutMs := 20000) {
	startedAt := A_TickCount
	while (A_TickCount - startedAt < timeoutMs) {
		if loggerWindow := FindLoggerWindow()
			return loggerWindow
		Sleep(25)
	}
	return 0
}
