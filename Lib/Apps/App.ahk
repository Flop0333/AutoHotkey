Class App {
    static Init(winTitle, ahk_exe, path := "") {
        this.winTitle := winTitle
        this.ahk_exe := ahk_exe
        this.path := path
    }
    
    static Activate() => WinActivate("ahk_exe " this.ahk_exe)
    static Maximize() => WinMaximize("ahk_exe " this.ahk_exe)
    static Minimize() => WinMinimize("ahk_exe " this.ahk_exe)
    
    static IsRunning() => ("ahk_exe " this.ahk_exe)
    
    static Launch(useExe := true) {
        if this.IsRunning() {
            try {
                this.Activate()
                this.Maximize()
                return
            }
        }
        DarkToolTip("Launching " this.winTitle).FollowMouse().AlignText("Center")
        RunWait(useExe ? this.ahk_exe : this.path)
        this.Maximize()

    }
}