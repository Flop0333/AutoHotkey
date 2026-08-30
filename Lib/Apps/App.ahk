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
    
    static Launch() {
        if this.IsRunning() {
            try this.Activate()
            catch {
                Run(this.ahk_exe)
            }
            return
        }

        if this.ahk_exe {
            Run(this.ahk_exe)
            return
        }
        Run(this.path)
    }
}