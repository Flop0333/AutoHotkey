; ============================================================================
; === Remote Board - Controller ===============================================
; ============================================================================
;
; One always-on-top WebView window with two modes:
;   - bubble: a small round, draggable button that floats over everything
;   - board:  the same window filling the work area with every action button,
;             including the bubble's own toggle tile to collapse it again
;
; The interface (User Interface/) owns layout and click-vs-drag detection;
; this controller owns window geometry, persistence, and running actions.
; ============================================================================

#Include ..\..\Lib\Core\Paths.ahk
#Include ..\..\Lib\Core\WebView.ahk
#Include ..\..\Lib\Extensions\Json.ahk

class RemoteButton {
    ; action runs on its own thread, so a slow action never blocks the board.
    __New(label, icon, action, image := "") {
        this.label := label
        this.icon := icon
        this.action := action
        this.image := image
    }
}

class RemoteBoard extends WebViewToo {
    static WIN_TITLE := "Remote Board"
    static BUBBLE_SIZE := 64 ; in 96-DPI pixels, scaled to the screen DPI

    __New(buttons, settingsPath := Paths.dashboards "\Remote Board\window settings.ini") {
        super.__New(, , , false) ; no custom caption: the bubble has no resize border
        this.buttons := buttons
        this.settingsPath := settingsPath
        this.mode := "bubble"
        this.bubbleSize := Round(RemoteBoard.BUBBLE_SIZE * A_ScreenDPI / 96)

        this.Gui.Opt("-Caption -Resize +AlwaysOnTop +ToolWindow -DPIScale")
        this.Gui.Title := RemoteBoard.WIN_TITLE

        uiPath := Paths.dashboards "\Remote Board\User Interface"
        iconsPath := Paths.dashboards "\Macro Board\User Interface\assets\icons"
        this.SetVirtualHostNameToFolderMapping("remote.local", uiPath, 0)
        this.SetVirtualHostNameToFolderMapping("icons.local", iconsPath, 0) ; shared with the Macro Board
        this.AddCallbackToScript("GetButtons", (*) => this._ButtonsJson())
        this.AddCallbackToScript("Trigger", (webView, index) => this._Trigger(index))
        this.AddCallbackToScript("ToggleBoard", (*) => this.Toggle())
        this.AddCallbackToScript("StartDrag", (*) => this.DragWindow())
        this.AddCallbackToScript("GetMode", (*) => this._GetMode())
        this.Load("http://remote.local/index.html")

        OnMessage(0x0232, (wParam, lParam, msg, hwnd) => this._OnMoveEnd(hwnd)) ; WM_EXITSIZEMOVE
    }

    IsShown => DllCall("IsWindowVisible", "Ptr", this.Gui.Hwnd)

    ; Shows the bubble without taking focus from the window being used.
    ShowBubble() => this._ApplyBubble()

    HideBoard() {
        this.Gui.Hide()
        this.mode := "bubble" ; the next ShowBubble restores the bubble geometry
        this._SetPageMode()
    }

    ToggleVisible() => this.IsShown ? this.HideBoard() : this.ShowBubble()

    ; Shows the full board directly, e.g. from the Macro Board button.
    OpenBoard() => this._ApplyBoard()

    Toggle() {
        if (this.mode = "board")
            this._ApplyBubble()
        else
            this._ApplyBoard()
    }

    ; Geometry goes through Show: a first Show without a position would center
    ; the window at its default size.
    _ApplyBubble() {
        this.mode := "bubble"
        pos := this._LoadBubblePos()
        size := this.bubbleSize
        WinSetRegion("0-0 W" size " H" size " E", this.Gui.Hwnd) ; round window
        this.Gui.Show(Format("NA x{} y{} w{} h{}", pos.x, pos.y, size, size))
        this._SetPageMode()
    }

    _ApplyBoard() {
        this.mode := "board"
        WinGetPos(&x, &y, , , this.Gui.Hwnd)
        MonitorGetWorkArea(this._MonitorAt(x + this.bubbleSize // 2, y + this.bubbleSize // 2), &left, &top, &right, &bottom)
        WinSetRegion(, this.Gui.Hwnd)
        ; Activate, so Esc reaches the page.
        this.Gui.Show(Format("x{} y{} w{} h{}", left, top, right - left, bottom - top))
        this._SetPageMode()
    }

    _SetPageMode() {
        this.Fill()
        this.ExecuteScript("window.RemoteBoardUi && RemoteBoardUi.setMode('" this.mode "')")
    }

    ; Asked by the page when it loads, since a mode change can come earlier.
    _GetMode() => this.mode

    _ButtonsJson() {
        list := []
        for button in this.buttons
            list.Push({label: button.label, icon: button.icon, image: button.image})
        return Json.Dump(list)
    }

    _Trigger(index) {
        if (index >= 1 && index <= this.buttons.Length)
            SetTimer(this.buttons[index].action, -1)
    }

    _OnMoveEnd(hwnd) {
        if (hwnd != this.Gui.Hwnd || this.mode != "bubble")
            return
        WinGetPos(&x, &y, , , this.Gui.Hwnd)
        try {
            IniWrite(x, this.settingsPath, "Bubble", "x")
            IniWrite(y, this.settingsPath, "Bubble", "y")
        }
    }

    ; The saved position, kept on a visible monitor; default: right edge, middle.
    _LoadBubblePos() {
        try {
            x := Integer(IniRead(this.settingsPath, "Bubble", "x"))
            y := Integer(IniRead(this.settingsPath, "Bubble", "y"))
            MonitorGetWorkArea(this._MonitorAt(x + this.bubbleSize // 2, y + this.bubbleSize // 2), &left, &top, &right, &bottom)
            return {x: Max(left, Min(x, right - this.bubbleSize)), y: Max(top, Min(y, bottom - this.bubbleSize))}
        }
        MonitorGetWorkArea(MonitorGetPrimary(), &left, &top, &right, &bottom)
        margin := this.bubbleSize // 4
        return {x: right - this.bubbleSize - margin, y: top + (bottom - top - this.bubbleSize) // 2}
    }

    _MonitorAt(x, y) {
        loop MonitorGetCount() {
            MonitorGet(A_Index, &left, &top, &right, &bottom)
            if (x >= left && x < right && y >= top && y < bottom)
                return A_Index
        }
        return MonitorGetPrimary()
    }
}
