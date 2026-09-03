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
#Include ..\..\Lib\Apps\VsCode.ahk
#Include ..\..\Lib\Apps\Notion.ahk
#Include ..\..\Lib\Apps\Spotify.ahk
#Include ..\..\Lib\Apps\WhatsApp.ahk
#Include ..\..\Lib\Apps\Browser.ahk

GetDesktopsForProfile() {
    desktopCounter := 0 ; Start at 0, increment for each desktop added
    config := Map()

    if (ProfileManager.Is(Profiles.devbox)) {
        devBoxDesktopsAmount := 10
        desktopCounter := DesktopsDDL.GetDesktopCount() = devBoxDesktopsAmount ? 0 : 1 ; Devbox has 'Local desktops' which takes the first slot, so we need to shift all desktops by 1

        config["1"] := Desktop(desktopCounter++) ; Because of 'Local desktops' in devbox, we start at 1 instead of 0
        config["2"] := Desktop(desktopCounter++)
        config["3"] := Desktop(desktopCounter++)

        config["R"] := Desktop(desktopCounter++,   RequiredWindows.WorkRepo)
        config["Y"] := Desktop(desktopCounter++,   RequiredWindows.YouTube)

        config["A"] := Desktop(desktopCounter++,   RequiredWindows.AutoHotkey)
        config["G"] := Desktop(desktopCounter++,   RequiredWindows.ChatGPTWeb)

        config["C"] := Desktop(desktopCounter++) ; for code
        config["B"] := Desktop(desktopCounter++,  RequiredWindows.WorkBoard)
        config["N"] := Desktop(desktopCounter++,  RequiredWindows.Notion)
    }

    if (ProfileManager.Is(Profiles.woonkamerLaptops)) {
        config["1"] := Desktop(desktopCounter++)
        config["2"] := Desktop(desktopCounter++)
        config["3"] := Desktop(desktopCounter++)

        config["W"] := Desktop(desktopCounter++,   RequiredWindows.WhatsApp)
        config["R"] := Desktop(desktopCounter++,   RequiredWindows.GitHub)
        config["Y"] := Desktop(desktopCounter++,   RequiredWindows.YouTube)

        config["A"] := Desktop(desktopCounter++,   RequiredWindows.AutoHotkey)
        config["S"] := Desktop(desktopCounter++,   RequiredWindows.Spotify)
        config["G"] := Desktop(desktopCounter++,   RequiredWindows.ChatGPTWeb, RequiredWindows.ChatGPTApp)

        config["C"] := Desktop(desktopCounter++,   RequiredWindows.Code)
        config["N"] := Desktop(desktopCounter++,  RequiredWindows.Notion)
    }

    return config
}

class RequiredWindows {
    static YouTube := RequiredWindow("YouTube", () => Brave.OpenURL(Links.youtube))
    static ChatGPTApp := RequiredWindow("ChatGPT", () => Run("ahk_exe ChatGPT.exe"),false)
    static ChatGPTWeb := RequiredWindow(Browser.defaultBrowser.winTitle, () => Browser.OpenURL(Links.chatGpt),false)
    static Notion := RequiredWindow("Notion", () => Notion.Launch())
    static Spotify := RequiredWindow("Spotify", () => Spotify.Launch())
    static WhatsApp := RequiredWindow("WhatsApp", () => WhatsApp.Launch())
    static Code := RequiredWindow("Code", () => VsCode.Launch())
    static GitHub := RequiredWindow(Browser.defaultBrowser.winTitle, () => Browser.OpenURL(Links.githubRepos))
    static AutoHotkey := RequiredWindow("Code", () => VsCode.openAutoHotkey())
    static WorkRepo := RequiredWindow(Browser.defaultBrowser.winTitle, () => Run(Browser.defaultBrowser.winTitle.ahk_exe " --new-window " Secrets.ApolloPullRequest.Get() " " Secrets.AthenaPullRequest.Get()))
    static WorkBoard := RequiredWindow(Browser.defaultBrowser.winTitle, () => Browser.OpenURL(Secrets.WorkBoard.Get()))
}

; ===== HOTKEY CONFIGURATION =====
desktops := GetDesktopsForProfile()

for key, desktopObj in desktops {
    handler := ((d) => (*) => HandleSwitch(d))(desktopObj)
    Capslock.Hotkey(key, handler)
}

; Foreward & Backward
Capslock.Hotkey("Tab", (*) => DesktopsDDL.GoToPrevious())
Capslock.Hotkey("P", (*) => DesktopsDDL.TogglePin())

; ===== HELPER FUNCTIONS =====
global onLeaveAction := ""
HandleSwitch(desktop) {
    global onLeaveAction
    desktop.SwitchTo(onLeaveAction)
    onLeaveAction := desktop.onLeaveAction
}
