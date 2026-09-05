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

USER_INTERFACE_PATH := Paths.dashboards "\Log Dashboard\User Interface"

myLogDashboard := LogDashboard()
