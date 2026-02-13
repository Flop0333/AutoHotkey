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

#Include ..\Lib\Core.ahk
#Include ..\Lib\Apps\Notion.ahk
#Include ..\Lib\Apps\Spotify.ahk
#Include ..\Lib\Apps\KeePass.ahk

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
#HotIf ProfileManager.Is(Profiles.woonkamerLaptops)
~LButton & N:: Notion.OpenPage(NotionPages.shitFixen)
~LButton & S:: Spotify.StartPlaylist(Playlist.goodMorningJazz)
~LButton & F:: OpenFinancien()
~LButton & C:: OpenCalendar()
~LButton & A:: OpenAI()
~LButton & W:: OpenWeer()
~LButton & M:: OpenGoogleMaps()


#HotIf ProfileManager.Is(Profiles.work)
CapsLock.Hotkey("D", (*) => KeePass.InsertMainPassword())
CapsLock.Hotkey("!D", (*) => KeePass.InsertSecondaryPassword())