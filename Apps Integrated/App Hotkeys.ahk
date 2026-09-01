#SingleInstance Force
#NoTrayIcon
#Include <Core\ErrorReporter>

AppSpecificHotkey.Set("ahk_exe Notion.exe", (*) => Send("^\"), AppSpecificHotkey.PRIMARY_SHORTCUT) ; Toggle sidebar

AppSpecificHotkey.Set("ahk_exe ms-teams.exe", (*) => Send("^+m"), AppSpecificHotkey.PRIMARY_SHORTCUT) ; Mute/unmute voice call

; ============================================================================
; === Visual Studio Code ===
; ============================================================================
AppSpecificHotkey.Set("ahk_exe Code.exe", (*) => (
	WinActive(".ahk") ? Send("^{F5}") : ; AutoHotkey 
	WinActive(".py") ? ErrorReporter.Notify("Not implemented", "App Hotkeys", "info") : ; Python
	WinActive("Angular") ? Send('^+``') Sleep(1000) Send('ng serve{enter}') : ; Angular 'ng serve'
	ErrorReporter.Notify("Not implemented", "App Hotkeys", "info")
), AppSpecificHotkey.PRIMARY_SHORTCUT)

AppSpecificHotkey.Set("ahk_exe Code.exe", (*) => (
	WinActive(".ahk") ? Send("{F5}") : ; AutoHotkey 
	ErrorReporter.Notify("Not implemented", "App Hotkeys", "info")
), AppSpecificHotkey.SECONDARY_SHORTCUT)



Class AppSpecificHotkey {

    static PRIMARY_SHORTCUT := "#Z"
    static SECONDARY_SHORTCUT := "#!Z"

	static Set(window, action, shortcut := this.PRIMARY_SHORTCUT) {
		HotIfWinActive window
		Hotkey(shortcut, action)
	}
}
