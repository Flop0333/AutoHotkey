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
        ; The board's window stays hidden while no Parsec guest is connected,
        ; so hidden windows must be detectable for both the lookup and the post.
        previous := DetectHiddenWindows(true)
        try {
            if hwnd := WinExist(RemoteBoardClient.WIN_TITLE) {
                PostMessage(RemoteBoardClient.OPEN_MESSAGE, 0, 0, , hwnd)
                return
            }
        } finally
            DetectHiddenWindows(previous)

        Run('"' A_AhkPath '" "' Paths.dashboards '\Remote Board\Remote Board.ahk" ' RemoteBoardClient.OPEN_ARGUMENT)
    }
}
