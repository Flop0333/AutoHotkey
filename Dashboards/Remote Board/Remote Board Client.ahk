; ============================================================================
; === Remote Board Client - Open the Remote Board from another script =========
; ============================================================================
;
; The Remote Board runs in its own process. Open() posts a message to its
; (possibly hidden) window, or starts it with the "open" argument when it is
; not running. Either way the full board is shown, also without Parsec.
;
; [USAGE]
;   RemoteBoardClient.Open()
; ============================================================================

#Include ..\..\Lib\Core\Paths.ahk

class RemoteBoardClient {
    static OPEN_MESSAGE := 0x8101 ; WM_APP + 0x101
    static WIN_TITLE := "Remote Board ahk_class AutoHotkeyGUI"
    static OPEN_ARGUMENT := "open"

    static Open() {
        previous := DetectHiddenWindows(true)
        hwnd := WinExist(RemoteBoardClient.WIN_TITLE)
        DetectHiddenWindows(previous)

        if hwnd
            PostMessage(RemoteBoardClient.OPEN_MESSAGE, 0, 0, , "ahk_id " hwnd)
        else
            Run('"' A_AhkPath '" "' Paths.dashboards '\Remote Board\Remote Board.ahk" ' RemoteBoardClient.OPEN_ARGUMENT)
    }
}
