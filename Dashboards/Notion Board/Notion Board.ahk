; ============================================================================
; Notion Board Dashboard - Notion board in its own persistent WebView2 window
; ============================================================================
;
; [FEATURES]
;   - Shows the Notion board from the NotionBoardUrl secret in a WebView2 host
;   - A fixed, persistent Browser Data folder keeps the Notion session
;     logged in across suite restarts; log in manually once
;   - Remembers the last windowed position and size across restarts
;   - Removes surrounding Notion controls for a focused board view
;
; [USAGE]
;   - CapsLock+N brings the window forward or sends it behind other windows
;   - Closing or minimizing sends it to the desktop instead
; ============================================================================

#SingleInstance Force
Persistent(true)
#Include ..\..\Lib\Core\OnError.ahk
#Include ..\..\Lib\Core\Paths.ahk
#Include ..\..\Lib\Helpers\Capslock.ahk
#Include ..\..\Profiles\Profile Manager.ahk
#Include Controller.ahk
TraySetIcon(Paths.autoHotkeyIcon)

; Only launch for woonkamer laptops. ExitApp for the others.
if (ProfileManager.IsNot(Profiles.woonkamerLaptops)) {
    LogAndNotifyInfo("Notion Board not launched. It will only launch for woonkamer laptops")
    ExitApp()
}

myNotionBoard := NotionBoardController()
myNotionBoard.InitializeOnDesktop()

CapsLock.Hotkey("n", (*) => myNotionBoard.Toggle())

