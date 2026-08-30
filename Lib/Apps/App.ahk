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
            MsgBox("App is already running, activating it instead.")
            try this.Activate()
            catch {
                MsgBox("Failed to activate app, trying to run it instead. ahk_exe: " this.ahk_exe   " path: " this.path)
                Run(this.ahk_exe)
            }
            return
        }

        if this.ahk_exe {
            MsgBox("App is not running, launching it now.")
            Run(this.ahk_exe)
            return
        }
        MsgBox("App is not running, but no ahk_exe is defined to launch it. Please define a path in the app class.")
        Run(this.path)
    }
}