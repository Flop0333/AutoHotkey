/*
    Example usage:
    DarkToolTip('Tooltip text')                                           ; Basic tooltip with 2s auto-close
    DarkToolTip('Tooltip text', 5000)                                     ; Tooltip with 5s auto-close
    DarkToolTip('Multi-line`ntooltip').FollowMouse()                      ; Tooltip that follows the cursor
    DarkToolTip('Centered`ntext').AlignText('Center')                     ; Tooltip with centered text alignment
    DarkToolTip('Tracking tooltip').FollowMouse().AlignText('Center')     ; Combined: follows cursor with centered text
 */

class DarkToolTip {
    __New(text, duration := 2000) {
        this.text := text
        this.duration := duration
        ToolTip(text)
        this._ApplyDarkTheme()
        SetTimer () => ToolTip(), -duration
    }

    FollowMouse() {
        tick := A_TickCount, SetTimer(Update, 20),
        Update() => (
            (A_TickCount-tick < this.duration)
            ? (ToolTip(this.text, , , WhichToolTip?))
            : (SetTimer(, 0), ToolTip(, , , WhichToolTip?))
        )
        return this
    }

     AlignText(Alignment := 'Center') {
         static DT_LEFT   := 0x00000000
         static DT_CENTER := 0x00000001
         static DT_RIGHT  := 0x00000002
         static Formats := Map('L', DT_LEFT, 'C', DT_CENTER, 'R', DT_RIGHT)
       
         Alignment := Formats[StrUpper(SubStr(Alignment, 1, 1))]
         tooltipHwnd := WinExist("ahk_class tooltips_class32")
         OnMessage 0x004E, WM_NOTIFY
         if tooltipHwnd {
              WinRedraw tooltipHwnd
         }
       
         WM_NOTIFY(wParam, lParam, *) {
             static NM_CUSTOMDRAW := -12
             if tooltipHwnd = NumGet(lParam, 0 * A_PtrSize, 'Ptr')  ; NMHDR : hwndFrom
             && wParam = NumGet(lParam, 1 * A_PtrSize, 'UInt')  ; NMHDR : idFrom
             && NM_CUSTOMDRAW = NumGet(lParam, 2 * A_PtrSize, 'Int')  ; NMHDR : code
                 NumPut 'UInt', Alignment, lParam, 16 + 8 * A_PtrSize  ; NMTTCUSTOMDRAW : uDrawFlags
         }
         return this
     }

    _ApplyDarkTheme() {
        hwnd := WinExist("ahk_class tooltips_class32")
        DllCall("UxTheme\SetWindowTheme", "Ptr", hwnd, "Ptr", StrPtr("DarkMode_Explorer"), "Ptr", StrPtr("ToolTip"))
    }
}
