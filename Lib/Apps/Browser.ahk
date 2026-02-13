#Include ..\Core.ahk
#Include App.ahk

OpenFinancien() =>  (Info("Open Financiën"), Run(Secrets.FinanceUrl.GetOrSet()))
OpenCalendar() =>   (Info("Open Calendar"), Run("https://calendar.google.com/calendar/u/1"))
OpenAI() =>         (Info("Open AI"), Run("https://chatgpt.com/"))
OpenWeer() =>       (Info("Open Weer"), Run(Secrets.WeatherUrl.GetOrSet()))
OpenGoogleMaps() => (Info("Open Google Maps"), Run(Secrets.GooglemapsUrl.GetOrSet()))

Class Browser extends App {
    static defaultBrowser := Brave
    static browsers := [Brave,Edge,Chrome]
    
    static __New() => this.Init(this.defaultBrowser.winTitle, this.defaultBrowser.ahk_exe)
    
    ; This needs to take into account if the window is on another desktop
    static OpenURL(url, newTab := true) {
        if !this.IsRunning() {
            this.Launch()
            WinWaitActive("ahk_exe " this.ahk_exe, "", 5)
        } else {
            this.Activate()
            WinWaitActive("ahk_exe " this.ahk_exe, "", 5)
        }
        Run(this.ahk_exe " " url)
    }


    static OpenUrlUnderMouse(url) {
        ; Get window under mouse
        MouseGetPos(, , &mouseWinID)
        mouseExe := WinGetProcessName(mouseWinID)
        
        ; Check if the window is a browser and open in that browser
        for index, browserClass in this.browsers {
            if (mouseExe = browserClass.ahk_exe) {
                Run(mouseExe " " url)
                return
            }
        }
        
        this.defaultBrowser.OpenURL(url) ; Use default if no browser found
    }

    static NewWindow() => Send("^n")

    static NewTab() => Send("^t")
    static CloseTab() => Send("^w")
    static NextTab() => Send("^{Tab}")
    static PreviousTab() => Send("^+{Tab}")
}

Class Brave extends Browser {
    static __New() => this.Init("Brave", "brave.exe")
}

Class Edge extends Browser {
    static __New() => this.Init("Microsoft Edge", "msedge.exe")
}

Class Chrome extends Browser {
    static __New() => this.Init("Google Chrome", "chrome.exe")
}