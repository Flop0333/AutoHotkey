#SingleInstance Force
#NoTrayIcon
#Include ..\Lib\Core.ahk
#Include Actions\App Hotkey Actions.ahk

AppHotkeyActions.Register()

AppSpecificHotkey.Set("ahk_exe Notion.exe", "notion.sidebar.toggle", AppSpecificHotkey.PRIMARY_SHORTCUT)

AppSpecificHotkey.Set("ahk_exe ms-teams.exe", "teams.microphone.toggle", AppSpecificHotkey.PRIMARY_SHORTCUT)

; ============================================================================
; === Visual Studio Code ===
; ============================================================================
RunVsCodePrimaryAction() => (
	WinActive(".ahk") ? Send("^{F5}") : ; AutoHotkey 
	WinActive(".py") ? MsgBox("Not implemented") : ; Python
	WinActive("Angular") ? Send('^+``') Sleep(1000) Send('ng serve{enter}') : ; Angular 'ng serve'
	MsgBox("Not implemented")
)

RunVsCodeSecondaryAction() => (
	WinActive(".ahk") ? Send("{F5}") : ; AutoHotkey 
	MsgBox("Not implemented")
)

AppSpecificHotkey.Set("ahk_exe Code.exe", "vscode.project-action.primary", AppSpecificHotkey.PRIMARY_SHORTCUT)
AppSpecificHotkey.Set("ahk_exe Code.exe", "vscode.project-action.secondary", AppSpecificHotkey.SECONDARY_SHORTCUT)



Class AppSpecificHotkey {

    static PRIMARY_SHORTCUT := "#Z"
    static SECONDARY_SHORTCUT := "#!Z"

	static Set(window, actionId, shortcut := this.PRIMARY_SHORTCUT) {
		HotIfWinActive window
		ActionBinding.BindHotkey(shortcut, actionId, "app-hotkeys")
		HotIf
	}
}
