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
#Include ..\Lib\Actions\Modules\Application Actions.ahk
#Include Actions\Hotkey Actions.ahk

HotkeyActions.Register()

; ================================
; Generic Hotkeys
; ================================
; VS Code
#HotIf WinActive("ahk_exe Code.exe")
^WheelUp::ActionBinding.Invoke("vscode.zoom-in", unset, "global-hotkeys")
^WheelDown::ActionBinding.Invoke("vscode.zoom-out", unset, "global-hotkeys")

; Google Calendar
#HotIf WinActive("Google Calendar")
^Left::ActionBinding.Invoke("calendar.previous-week", unset, "global-hotkeys")
^Right::ActionBinding.Invoke("calendar.next-week", unset, "global-hotkeys")


; ================================
; Profile-specific Hotkeys
; ================================
#HotIf ProfileManager.Is(Profiles.work)
CapsLock.Hotkey("D", ActionBinding.Callback("keepass.main-password.insert", "global-hotkeys"))
CapsLock.Hotkey("!D", ActionBinding.Callback("keepass.secondary-password.insert", "global-hotkeys"))
