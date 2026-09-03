; Credits to https://github.com/adrian88888888/AHK-Virtual-Desktop-Library/tree/main/lib/AHK-Virtual-Desktop-Library/3rd%20party
#Include ..\..\Core\Paths.ahk
#Include ..\..\Extensions\Dark ToolTip.ahk
SetWorkingDir(A_ScriptDir)

Class DesktopsDDL {

static DESKTOP_ACCESSOR_PATH   := Paths.lib "\Tools\Desktops DLL Library\VirtualDesktopAccessor.dll"
    static DESKTOP_ACCESSOR        := DllCall("LoadLibrary", "Str", this.DESKTOP_ACCESSOR_PATH, "Ptr")
    
    static desktopsHistory := []
   
    static SendWindowToDesktop(number, activeHwnd) => DllCall(DllCall("GetProcAddress", "Ptr", this.DESKTOP_ACCESSOR, "AStr", "MoveWindowToDesktopNumber", "Ptr"), "Ptr", activeHwnd, "Int", number, "Int")
    static GetCurrentDesktopNumber() => DllCall(DllCall("GetProcAddress", "Ptr", this.DESKTOP_ACCESSOR, "AStr", "GetCurrentDesktopNumber", "Ptr"), "Int")
    static GoToDesktopNumber(number) => DllCall(DllCall("GetProcAddress", "Ptr", this.DESKTOP_ACCESSOR, "AStr", "GoToDesktopNumber", "Ptr"), "Int", number, "Int")
    static GetDesktopCount() => DllCall(DllCall("GetProcAddress", "Ptr", this.DESKTOP_ACCESSOR, "AStr", "GetDesktopCount", "Ptr"), "Int")
    static PinWindow(hwnd) => DllCall(DllCall("GetProcAddress", "Ptr", this.DESKTOP_ACCESSOR, "AStr", "PinWindow", "Ptr"), "UInt", hwnd)
    static UnpinWindow(hwnd) => DllCall(DllCall("GetProcAddress", "Ptr", this.DESKTOP_ACCESSOR, "AStr", "UnPinWindow", "Ptr"), "UInt", hwnd)
    static IsWindowPinned(hwnd) => DllCall(DllCall("GetProcAddress", "Ptr", this.DESKTOP_ACCESSOR, "AStr", "IsPinnedWindow", "Ptr"), "UInt", hwnd)
    static PinApp(hwnd) => DllCall(DllCall("GetProcAddress", "Ptr", this.DESKTOP_ACCESSOR, "AStr", "PinApp", "Ptr"), "UInt", hwnd)
    static UnpinApp(hwnd) => DllCall(DllCall("GetProcAddress", "Ptr", this.DESKTOP_ACCESSOR, "AStr", "UnPinApp", "Ptr"), "UInt", hwnd)
    static IsAppPinned(hwnd) => DllCall(DllCall("GetProcAddress", "Ptr", this.DESKTOP_ACCESSOR, "AStr", "IsPinnedApp", "Ptr"), "UInt", hwnd)
    static _IsWindowOnDesktopNumberProc := DllCall("GetProcAddress", "Ptr", this.DESKTOP_ACCESSOR, "AStr", "IsWindowOnDesktopNumber", "Ptr")
    static IsWindowOnDesktop(number, hwnd) => DllCall(this._IsWindowOnDesktopNumberProc, "Ptr", hwnd, "Int", number, "Int")

    /**
     * Moves normal application windows from every other virtual desktop to the
     * desktop which is active when this method starts.
     *
     * Pinned windows/apps, shell windows, tool windows and windows which do not
     * belong to a virtual desktop are deliberately left untouched.
     */
    static PullAllWindowsToCurrentDesktop() {
        result := MsgBox("Move all windows to this desktop?", "Single Desktop Mode", "YesNo")
		if (result = "No")
			return

        currentDesktop := this.GetCurrentDesktopNumber()
        desktopCount := this.GetDesktopCount()
        result := {moved: 0, failed: 0, skipped: 0, targetDesktop: currentDesktop}
        previousDetectHiddenWindows := A_DetectHiddenWindows

        DetectHiddenWindows(true)
        try {
            for hwnd in WinGetList() {
                if !this._ShouldMoveWindow(hwnd, currentDesktop, desktopCount) {
                    result.skipped += 1
                    continue
                }

                try {
                    this.SendWindowToDesktop(currentDesktop, hwnd)
                    if this.IsWindowOnDesktop(currentDesktop, hwnd)
                        result.moved += 1
                    else
                        result.failed += 1
                } catch {
                    ; Elevated or protected windows can reject desktop moves.
                    result.failed += 1
                }
            }
        } finally {
            DetectHiddenWindows(previousDetectHiddenWindows)
        }

        return result
    }

    static _ShouldMoveWindow(hwnd, currentDesktop, desktopCount) {
        static WS_VISIBLE := 0x10000000
        static WS_EX_TOOLWINDOW := 0x00000080
        static excludedClasses := Map(
            "Progman", true,
            "WorkerW", true,
            "Shell_TrayWnd", true,
            "Shell_SecondaryTrayWnd", true
        )

        try {
            if hwnd = A_ScriptHwnd
                return false
            if !(WinGetStyle(hwnd) & WS_VISIBLE)
                return false
            if WinGetExStyle(hwnd) & WS_EX_TOOLWINDOW
                return false
            if WinGetTitle(hwnd) = ""
                return false
            if excludedClasses.Has(WinGetClass(hwnd))
                return false
            if this.IsWindowPinned(hwnd) || this.IsAppPinned(hwnd)
                return false
            if this.IsWindowOnDesktop(currentDesktop, hwnd)
                return false

            ; Avoid moving system windows which are not assigned to any desktop.
            Loop desktopCount {
                desktopNumber := A_Index - 1
                if desktopNumber != currentDesktop && this.IsWindowOnDesktop(desktopNumber, hwnd)
                    return true
            }
        }

        return false
    }

    static GotoDesktop(number) {
        this._SetTeamsCallOnTop()
        GetKeyState("LButton") ? this._MoveCurrentWindowToDesktop(number) : this.GoToDesktopNumber(number)
        if !GetKeyState("LButton") {
            try WinActivate(Win.WinUnderMouse())
        }
    }

    static GoToPrevious() {
        try this.desktopsHistory.Pop()
        try this.GotoDesktop(this.desktopsHistory[this.desktopsHistory.Length])
    }

    static TogglePin(hwnd := ""){
        if hwnd = ""
            hwnd := WinGetID(Win.WinUnderMouse())
        windowIsPinned := this.IsWindowPinned(hwnd)

        if windowIsPinned {
            this.UnpinWindow(hwnd)
            DarkToolTip("Unpinned").FollowMouse()
            if !Win.IsAlwaysOnTop()
                Win.RemoveBorder()
        } 
        else {
            this.PinWindow(hwnd)
            Win.SetBorderColor(,0xFF0000)
            DarkToolTip("Pinned").FollowMouse()
        }
    }

    static _MoveCurrentWindowToDesktop(number) {
        this.SendWindowToDesktop(number, WinGetID("A"))
        this.GoToDesktopNumber(number)
    }

    static _SetTeamsCallOnTop() {
        textToExclude := "(Chat|Agenda|kanalen)"
    
        for winId in WinGetList("Teams") {
            if !RegExMatch(WinGetTitle(winId), textToExclude)
                WinSetAlwaysOnTop(, winId)
        }
    }
}
