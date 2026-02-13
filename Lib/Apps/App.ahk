Class App {
    static Init(winTitle, ahk_exe, path := "") {
        this.winTitle := winTitle
        this.ahk_exe := ahk_exe
        this.path := path
    }
    
    static Activate() => WinActivate("ahk_exe " this.ahk_exe)
    static Maximize() => WinMaximize("ahk_exe " this.ahk_exe)
    static Minimize() => WinMinimize("ahk_exe " this.ahk_exe)
    
    static IsRunning() => WinExist(this.winTitle)
    
    static Launch() {
        if this.IsRunning() {
            this.Activate()
            return
        }

        if this.path {
            Run(this.path)
            return
        }

        Run(this.ahk_exe)
    }
}