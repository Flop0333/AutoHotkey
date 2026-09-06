; ============================================================================
; Logging - Public facade for the shared logger and log dashboard
; ============================================================================
;
; Startup calls InitializeLogging() exactly once per suite start. Other scripts
; include this file to use Log*, LogAndNotify*, Show/HideLogger, and
; Show/HideLogDashboard without creating their own UI instances.

#Include ..\..\Lib\Core\OnError.ahk
#Include Logger.ahk
#Include ..\Log Dashboard\Log Dashboard.ahk

InitializeLogging() {
	ClearErrorLog()

	; Both host scripts use #SingleInstance Force. Starting them here replaces
	; instances left over from an earlier startup with fresh session-owned hosts.
	StartLogger()
	loggerWindow := WaitForLoggerWindow()
	StartLogDashboard()
	dashboardWindow := WaitForLogDashboardWindow()

	if !dashboardWindow || !loggerWindow
		throw Error("Failed to initialize the logger UI hosts")

	return Map("dashboard", dashboardWindow, "logger", loggerWindow)
}
