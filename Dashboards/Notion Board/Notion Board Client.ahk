#Include ..\..\Lib\Core\Paths.ahk

; Launches the Djengus board on demand or forwards a request to its window.
class NotionBoardClient {
    static OPEN_MESSAGE := 0x8102 ; WM_APP + 0x102
    static MACRO_OPEN_MESSAGE := 0x8103
    static WIN_TITLE := "Notion Board"

    ; Both entry points dispatch through the service so a macro click and
    ; the keyboard shortcut cannot launch competing hosts.
    static OpenFromMacro() {
        previous := DetectHiddenWindows(true)
        try PostMessage(this.MACRO_OPEN_MESSAGE, 0, 0, ,
            Paths.appsStandalone "\Capslock Service.ahk ahk_class AutoHotkey")
        finally DetectHiddenWindows(previous)
    }

    static Open(toggle := false) {
        static launchingPid := 0

        previous := A_IsCritical
        Critical("On")
        try {
            if hwnd := WinExist(this.WIN_TITLE " ahk_class AutoHotkeyGUI") {
                try {
                    PostMessage(this.OPEN_MESSAGE, toggle, 0, , hwnd)
                    return
                } catch TargetError {
                    ; The board closed between the lookup and the post.
                }
            }

            ; The process can be running before its WebView window is ready.
            if !ProcessExist(launchingPid)
                Run('"' A_AhkPath '" "' Paths.dashboards '\Notion Board\Notion Board.ahk"', , , &launchingPid)
        } finally Critical(previous)
    }
}
