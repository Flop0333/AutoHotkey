; ============================================================================
; === Hotkeys - Global and profile-specific hotkey definitions ================
; ============================================================================
;
; [PURPOSE]
;   Central location for application-specific and profile-based hotkeys.
;   Separates generic hotkeys from profile-specific behaviors.
;
; [ORGANIZATION]
;   - Generic Hotkeys: Application-specific keys (VS Code, Calendar, etc.)
;   - Profile-specific: Keys that change behavior based on active profile
;
; [USAGE]
;   Hotkeys are automatically active when their context matches:
;   - #HotIf WinActive(...) for app-specific keys
;   - ProfileManager.Is(...) for profile-based keys
;
; [EXAMPLES]
;   Generic: Ctrl+Wheel to zoom in VS Code
;   Profile: LButton+N opens Notion on home laptops only
; ============================================================================
#NoTrayIcon
#Include ..\Lib\Core\OnError.ahk
#Include ..\Lib\Helpers\Capslock.ahk
#Include ..\Profiles\Profile Manager.ahk
#Include ..\Lib\Apps\Notion.ahk
#Include ..\Lib\Apps\Spotify.ahk
#Include ..\Lib\Apps\KeePass.ahk
#Include ..\Lib\Apps\PhilipsTv.ahk
#Include ..\Lib\Apps\YouTube.ahk
#Include ..\Lib\Core\Links.ahk
#Include ..\Lib\Helpers\DoubleTap.ahk

; ================================
; Generic Hotkeys
; ================================
; VS Code
#HotIf WinActive("ahk_exe Code.exe")
^WheelUp::Send("{Ctrl Down}{+}{Ctrl Up}") ; Zoom in
^WheelDown::Send("{Ctrl Down}{-}{Ctrl Up}") ; Zoom out

; Google Calendar
#HotIf WinActive("Google Calendar")
^Left::Send("k") ;Jump week foreward
^Right::Send("j") ;Jump week backward


; ================================
; Profile-specific Hotkeys
; ================================
#HotIf ProfileManager.Is(Profiles.work)
CapsLock.Hotkey("D", (*) => KeePass.InsertMainPassword())
CapsLock.Hotkey("!D", (*) => KeePass.InsertSecondaryPassword())
#HotIf

; Djengus: double tap an F-key; a single tap keeps its normal function
if ProfileManager.Is(Profiles.djengus) {
    DoubleTap.Hotkey("F1", () => PhilipsTv.On())
    DoubleTap.Hotkey("F2", () => PhilipsTv.Off())
    DoubleTap.Hotkey("F3", () => Run(Links.youtube))
    DoubleTap.Hotkey("F4", () => StartSpotifyGoodMorningJazz())
    DoubleTap.Hotkey("F5", StartWoonkamerScene)
}

; Tv on, jazz on Spotify, and a muted YouTube video fullscreen as backdrop.
; Spotify goes first: opening the playlist activates its window, which would
; otherwise pull focus away from the fullscreen video.
StartWoonkamerScene() {
    PhilipsTv.On()
    try StartSpotifyGoodMorningJazz()
    YouTube.PlayFullscreen("RDfjXj5EGqI", 0, true) ; from the start, muted
}
