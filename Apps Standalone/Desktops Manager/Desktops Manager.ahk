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

GetDesktopsForProfile() {
    config := Map()
    config["1"] := Desktop(0)
    config["2"] := Desktop(1)
    config["3"] := Desktop(2)
    
    if (ProfileManager.Is(Profiles.devbox)) {
        config["R"] := Desktop(3,   RequiredWindow("Edge",      () => Run(Links.work.apolloPullRequest) Run(Links.work.athenaPullRequest))),
        config["Y"] := Desktop(4,   RequiredWindow("YouTube",   () => Run(Links.youtube)))
        
        config["A"] := Desktop(5,   RequiredWindow("Code",      () => Run("C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Visual Studio Code\Visual Studio Code.lnk C:\Users\BremerF\Documents\AutoHotkey",,"Max")))
        config["G"] := Desktop(6,   RequiredWindow("Edge",      () => Run(Links.chatGpt)))
        
        config["B"] := Desktop(7,  RequiredWindow("Edge",      () => Run(Links.work.board)))
        config["N"] := Desktop(8,  RequiredWindow("Notion",    () => WinMaximize("ahk_exe Notion.exe")))
                                        .OnLeave(() => WinMinimize("ahk_exe Notion.exe"))
    }

    if (ProfileManager.Is(Profiles.woonkamerLaptops)) {
        config["Q"] := Desktop(3,   RequiredWindow("YouTube",   () => Run(Links.youtube)))
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