; ============================================================================
; Notion Board Dashboard - Notion board in its own persistent WebView2 window
; ============================================================================
;
; [FEATURES]
;   - Shows the Notion board from the NotionBoardUrl secret in a WebView2 host
;   - A fixed, persistent WebView2 profile folder keeps the Notion session
;     logged in across suite restarts; log in manually once
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

CapsLock.Hotkey("n", (*) => ToggleNotionBoard())

ToggleNotionBoard() => WinActive("ahk_id " myNotionBoard.Hwnd) ? myNotionBoard.SendToDesktop() : myNotionBoard.Show()
