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
^WheelUp::ActionBinding.Invoke(ActionIds.Application.VsCodeZoomIn, unset, "global-hotkeys")
^WheelDown::ActionBinding.Invoke(ActionIds.Application.VsCodeZoomOut, unset, "global-hotkeys")

; Google Calendar
#HotIf WinActive("Google Calendar")
^Left::ActionBinding.Invoke(ActionIds.Application.CalendarPreviousWeek, unset, "global-hotkeys")
^Right::ActionBinding.Invoke(ActionIds.Application.CalendarNextWeek, unset, "global-hotkeys")


; ================================
; Profile-specific Hotkeys
; ================================
#HotIf ProfileManager.Is(Profiles.work)
CapsLock.Hotkey("D", ActionBinding.Callback(ActionIds.Application.KeePassMainPassword, "global-hotkeys"))
CapsLock.Hotkey("!D", ActionBinding.Callback(ActionIds.Application.KeePassSecondaryPassword, "global-hotkeys"))
