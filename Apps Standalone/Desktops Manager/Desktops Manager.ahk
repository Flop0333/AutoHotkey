; ============================================================================
; === Desktops Manager - Manage virtual desktops with custom configurations ==
; ============================================================================
;
; [FEATURES]
; - Auto-launch and activate applications when switching to a desktop
; - Configure different desktop layouts per profile (work, personal, etc.)
; - Custom on-leave actions when switching away from desktops
; - Visual "Launching..." notification when opening apps
;
; [HOTKEYS]
; - Capslock + Key - Switch to configured desktop (Alt + Key on VM/devbox)
; - Capslock + Tab - Go to previous desktop
; - Capslock + P - Toggle pin window to all desktops
;
; [SETUP]
; Edit GetDesktopsForProfile() to assign keys to desktops
; Example: config["Q"] := Desktop(3, RequiredWindow("Chrome", () => Run("chrome.exe")))
;   
; Options:
;   - activate := false     Launch app minimized/in background
;   - .OnLeave(() => Code)  Execute action when leaving desktop
;   - Multiple RequiredWindow() per desktop supported
; ============================================================================

#Include ..\..\Lib\Core.ahk
#Include Desktop.ahk
; #Include <Apps\Spotify>
; #Include <Apps\Notion>

GetDesktopsForProfile() {
    config := Map()
    
    if (ProfileManager.Is(Profiles.devbox)) {
        devBoxDesktopsAmount := 10
        startPos := DesktopsDDL.GetDesktopCount() = devBoxDesktopsAmount ? 0 : 1 ; Devbox has 'Local desktops' which takes the first slot, so we need to shift all desktops by 1
        config["1"] := Desktop(startPos) ; Because of 'Local desktops' in devbox, we start at 1 instead of 0
        config["2"] := Desktop(startPos + 1)
        config["3"] := Desktop(startPos + 2)
        config["R"] := Desktop(startPos + 3,   RequiredWindow("Edge",      () => Run(Browser.defaultBrowser.ahk_exe " --new-window " Secrets.ApolloPullRequest.Get() " " Secrets.AthenaPullRequest.Get())))
        config["Y"] := Desktop(startPos + 4,   RequiredWindow("YouTube",   () => Run(Browser.defaultBrowser.ahk_exe " --new-window " Links.youtube))) 
        
        config["A"] := Desktop(startPos + 5,   RequiredWindow("Code",      () => Run("C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Visual Studio Code\Visual Studio Code.lnk C:\Users\BremerF\Documents\AutoHotkey",,"Max")))
        config["G"] := Desktop(startPos + 6,   RequiredWindow("Edge",      () => Run(Browser.defaultBrowser.ahk_exe " --new-window " Links.chatGpt)))
        
        config["C"] := Desktop(startPos + 7) ; for code
        config["B"] := Desktop(startPos + 8,  RequiredWindow("Edge",      () => Run(Browser.defaultBrowser.ahk_exe " --new-window " Secrets.WorkBoard.Get())))
        config["N"] := Desktop(startPos + 9,  RequiredWindow("Notion",    () => WinMaximize("ahk_exe Notion.exe")))
                                        .OnLeave(() => WinMinimize("ahk_exe Notion.exe"))
    } else {
        config["1"] := Desktop(0)
        config["2"] := Desktop(1)
        config["3"] := Desktop(2)
    }

    if (ProfileManager.Is(Profiles.woonkamerLaptops)) {
        config["Q"] := Desktop(3,   RequiredWindow("YouTube",   () => Browser.OpenInNewBrowser(Links.youtube)))
        config["W"] := Desktop(4) ; WhatsApp

        config["A"] := Desktop(5,   RequiredWindow("Code",      () => Run(A_AppData "\Microsoft\Windows\Start Menu\Programs\Visual Studio Code\Visual Studio Code.lnk " A_MyDocuments "\AutoHotkey",,"Max")))
        config["S"] := Desktop(6,   RequiredWindow("Spotify",   () => Spotify.Launch()))
        config["G"] := Desktop(7,   RequiredWindow("Brave",     () => Browser.OpenInNewBrowser(Links.chatGpt)))
        
        config["C"] := Desktop(8,   RequiredWindow("Calendar",   () => Browser.OpenInNewBrowser(Links.googleCalendar)))
        config["V"] := Desktop(9) ; VM
        config["N"] := Desktop(10,  RequiredWindow("Notion",    () => Notion.Launch()))
                                .OnLeave(() => Notion.Minimize())

    }
    
    return config
}

; ===== HOTKEY CONFIGURATION =====
desktops := GetDesktopsForProfile()

; On devbox, use Alt instead of Capslock for switching
if ProfileManager.Is(Profiles.work) {
    for key, desktopObj in desktops
        Hotkey("Alt & " . key, ((d) => (*) => HandleSwitch(d))(desktopObj))
}
else {
    for key, desktopObj in desktops
        Capslock.Hotkey(key, ((d) => (*) => HandleSwitch(d))(desktopObj))

    ; Foreward & Backward
    Capslock.Hotkey("Tab", (*) => DesktopsDDL.GoToPrevious())
    Capslock.Hotkey("P", (*) => DesktopsDDL.TogglePin())
}

; ===== HELPER FUNCTIONS =====
global onLeaveAction := ""
HandleSwitch(desktop) {
    global onLeaveAction
    desktop.SwitchTo(onLeaveAction)
    onLeaveAction := desktop.onLeaveAction
}