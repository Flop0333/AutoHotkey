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
    static PinWindow(hwnd) => DllCall(DllCall("GetProcAddress", "Ptr", this.DESKTOP_ACCESSOR, "AStr", "PinWindow", "Ptr"), "UInt", hwnd)
    static UnpinWindow(hwnd) => DllCall(DllCall("GetProcAddress", "Ptr", this.DESKTOP_ACCESSOR, "AStr", "UnPinWindow", "Ptr"), "UInt", hwnd)
    static IsWindowPinned(hwnd) => DllCall(DllCall("GetProcAddress", "Ptr", this.DESKTOP_ACCESSOR, "AStr", "IsPinnedWindow", "Ptr"), "UInt", hwnd)
    static PinApp(hwnd) => DllCall(DllCall("GetProcAddress", "Ptr", this.DESKTOP_ACCESSOR, "AStr", "PinApp", "Ptr"), "UInt", hwnd)
    static UnpinApp(hwnd) => DllCall(DllCall("GetProcAddress", "Ptr", this.DESKTOP_ACCESSOR, "AStr", "UnPinApp", "Ptr"), "UInt", hwnd)
    static IsAppPinned(hwnd) => DllCall(DllCall("GetProcAddress", "Ptr", this.DESKTOP_ACCESSOR, "AStr", "IsPinnedApp", "Ptr"), "UInt", hwnd)
    static _isWindowOnDesktopProc := DllCall("GetProcAddress", "Ptr", this.DESKTOP_ACCESSOR, "AStr", "IsWindowOnDesktopNumber", "Ptr")
    static _IsWindowOnDesktopNumberProc := DllCall("GetProcAddress", "Ptr", this.DESKTOP_ACCESSOR, "AStr", "IsWindowOnDesktopNumber", "Ptr")

    static GotoDesktop(number) {
        this._SetTeamsCallOnTop()
        GetKeyState("LButton") ? this._MoveCurrentWindowToDesktop(number) : this.GoToDesktopNumber(number)
        if !GetKeyState("LButton") {
            CaptureCapslockReleaseOnHost()
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

CaptureCapslockReleaseOnHost() {
    ; Check if VM is under mouse
    if WinGetClass(Win.WinUnderMouse()) != "TscShellContainerClass" 
        return

    ; Make sure that the release of the capslock does get captured by the host, not by the VM. 
    ; If this is not done, the host is stuck with the capslock down state
    WinActivate("ahk_class Shell_TrayWnd") ; Activate the taskbar of the host
    KeyWait('CapsLock') ; wait for Capslock to be released, to capture it in the host
}