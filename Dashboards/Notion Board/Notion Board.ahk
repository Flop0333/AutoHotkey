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
;   - On Djengus the board starts on demand and closes its WebView2 on exit
;   - Minimizing sends it to the desktop
; ============================================================================

#SingleInstance Force
#Include ..\..\Lib\Core\OnError.ahk
#Include ..\..\Lib\Core\Paths.ahk
#Include ..\..\Lib\Helpers\Capslock.ahk
#Include ..\..\Profiles\Profile Manager.ahk
#Include Controller.ahk
#Include Notion Board Client.ahk
TraySetIcon(Paths.autoHotkeyIcon)

; Only launch for woonkamer laptops. ExitApp for the others.
if !ProfileManager.Is(Profiles.woonkamerLaptops, Profiles.djengus) {
    LogAndNotifyInfo("Notion Board not launched. It will only launch for woonkamer laptops")
    ExitApp()
}

onDemand := ProfileManager.Is(Profiles.djengus)
myNotionBoard := NotionBoardController(onDemand)

if onDemand {
    OnExit((*) => myNotionBoard.Release())
    OnMessage(NotionBoardClient.OPEN_MESSAGE, HandleNotionBoardOpen)
    myNotionBoard.OpenWithSavedGeometry()
} else {
    myNotionBoard.InitializeOnDesktop()
    CapsLock.Hotkey("n", (*) => myNotionBoard.Toggle())
}

HandleNotionBoardOpen(toggle, lParam, msg, hwnd) {
    if (hwnd = myNotionBoard.Hwnd) {
        if toggle
            myNotionBoard.Toggle()
        else
            myNotionBoard.Show()
    }
}

