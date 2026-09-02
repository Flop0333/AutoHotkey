#SingleInstance Force
#NoTrayIcon
#Include ..\Lib\Core\Notifier.ahk

AppSpecificHotkey.Set("ahk_exe Notion.exe", (*) => Send("^\"), AppSpecificHotkey.PRIMARY_SHORTCUT) ; Toggle sidebar

AppSpecificHotkey.Set("ahk_exe ms-teams.exe", (*) => Send("^+m"), AppSpecificHotkey.PRIMARY_SHORTCUT) ; Mute/unmute voice call

; ============================================================================
; === Visual Studio Code ===
; ============================================================================
AppSpecificHotkey.Set("ahk_exe Code.exe", (*) => (
	WinActive(".ahk") ? Send("^{F5}") : ; AutoHotkey 
	WinActive(".py") ? Notifier.Info("Not implemented", "App Hotkeys") : ; Python
	WinActive("Angular") ? Send('^+``') Sleep(1000) Send('ng serve{enter}') : ; Angular 'ng serve'
	Notifier.Info("Not implemented", "App Hotkeys")
), AppSpecificHotkey.PRIMARY_SHORTCUT)

AppSpecificHotkey.Set("ahk_exe Code.exe", (*) => (
	WinActive(".ahk") ? Send("{F5}") : ; AutoHotkey 
	Notifier.Info("Not implemented", "App Hotkeys")
), AppSpecificHotkey.SECONDARY_SHORTCUT)



Class AppSpecificHotkey {

    static PRIMARY_SHORTCUT := "#Z"
    static SECONDARY_SHORTCUT := "#!Z"

	static Set(window, action, shortcut := this.PRIMARY_SHORTCUT) {
		HotIfWinActive window
		Hotkey(shortcut, action)
	}
}
