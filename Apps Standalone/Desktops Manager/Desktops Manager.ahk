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
#Include ..\..\Lib\Core\CallbackAdapters.ahk
#Include Desktop.ahk
#Include ..\..\Lib\Apps\VsCode.ahk
#Include ..\..\Lib\Apps\Notion.ahk
#Include ..\..\Lib\Apps\Spotify.ahk
#Include ..\..\Lib\Apps\WhatsApp.ahk


GetDesktopsForProfile() {
    desktopCounter := 0 ; Start at 0, increment for each desktop added
    config := Map()
    
    if (ProfileManager.Is(Profiles.devbox)) {
        devBoxDesktopsAmount := 10
        desktopCounter := DesktopsDDL.GetDesktopCount() = devBoxDesktopsAmount ? 0 : 1 ; Devbox has 'Local desktops' which takes the first slot, so we need to shift all desktops by 1

        config["1"] := Desktop(desktopCounter++) ; Because of 'Local desktops' in devbox, we start at 1 instead of 0
        config["2"] := Desktop(desktopCounter++)
        config["3"] := Desktop(desktopCounter++)
        
        config["R"] := Desktop(desktopCounter++,   RequiredWindow("Edge",      () => Run(Browser.defaultBrowser.ahk_exe " --new-window " Secrets.ApolloPullRequest.Get() " " Secrets.AthenaPullRequest.Get())))
        config["Y"] := Desktop(desktopCounter++,   RequiredWindow("YouTube",   () => Run(Brave.ahk_exe " --new-window " Links.youtube))) 
        
        config["A"] := Desktop(desktopCounter++,   RequiredWindow("Code",      () => Run("C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Visual Studio Code\Visual Studio Code.lnk C:\Users\BremerF\Documents\AutoHotkey",,"Max")))
        config["G"] := Desktop(desktopCounter++,   RequiredWindow("Edge",      () => Run(Browser.defaultBrowser.ahk_exe " --new-window " Links.chatGpt)))
        
        config["C"] := Desktop(desktopCounter++) ; for code
        config["B"] := Desktop(desktopCounter++,  RequiredWindow("Edge",      () => Run(Browser.defaultBrowser.ahk_exe " --new-window " Secrets.WorkBoard.Get())))
        config["N"] := Desktop(desktopCounter++,  RequiredWindow("Notion",    () => WinMaximize("ahk_exe Notion.exe")))
                                        .OnLeave(() => WinMinimize("ahk_exe Notion.exe"))
    }

    if (ProfileManager.Is(Profiles.woonkamerLaptops)) {
        config["1"] := Desktop(desktopCounter++)
        config["2"] := Desktop(desktopCounter++)
        config["3"] := Desktop(desktopCounter++)

        config["W"] := Desktop(desktopCounter++,   RequiredWindow("WhatsApp",    () => WhatsApp.Launch()))
        config["Y"] := Desktop(desktopCounter++,   RequiredWindow("YouTube",    () => Browser.OpenInNewBrowser(Links.youtube))) 
        
        config["A"] := Desktop(desktopCounter++,   RequiredWindow("Code",       () => VsCode.openAutoHotkey()))
        config["S"] := Desktop(desktopCounter++,   RequiredWindow("Spotify",    () => Spotify.Launch()))
        config["G"] := Desktop(desktopCounter++,   RequiredWindow("ChatGPT",    () => Run("ahk_exe ChatGPT.exe")),
                                                    RequiredWindow("Brave",    () => Browser.OpenInNewBrowser(Links.chatGpt)))
        
        config["C"] := Desktop(desktopCounter++,   RequiredWindow("Code",       () => VsCode.Launch()))
        config["N"] := Desktop(desktopCounter++,  RequiredWindow("Notion",      () => Notion.Launch()))
    }
    
    return config
}

; ===== HOTKEY CONFIGURATION =====
desktops := GetDesktopsForProfile()

for key, desktopObj in desktops {
    operationId := "desktops.switch." key
    handler := CallbackAdapters.MakeHotkeyHandler(operationId, ((d) => (*) => HandleSwitch(d))(desktopObj), { serviceId: "desktops_manager" })
    Capslock.Hotkey(key, handler)
}

; Foreward & Backward
Capslock.Hotkey("Tab", CallbackAdapters.MakeHotkeyHandler("desktops.previous", (*) => DesktopsDDL.GoToPrevious(), { serviceId: "desktops_manager" }))
Capslock.Hotkey("P", CallbackAdapters.MakeHotkeyHandler("desktops.toggle_pin", (*) => DesktopsDDL.TogglePin(), { serviceId: "desktops_manager" }))

; ===== HELPER FUNCTIONS =====
global onLeaveAction := ""
HandleSwitch(desktop) {
    global onLeaveAction
    desktop.SwitchTo(onLeaveAction)
    onLeaveAction := desktop.onLeaveAction
}
