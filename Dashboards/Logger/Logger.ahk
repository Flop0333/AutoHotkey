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

USER_INTERFACE_PATH := Paths.dashboards "\Logger\User Interface"

myLogger := LoggerPopup()
