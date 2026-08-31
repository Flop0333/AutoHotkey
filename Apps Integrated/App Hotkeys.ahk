#SingleInstance Force
#NoTrayIcon
#Include ..\Lib\Core.ahk
#Include Actions\App Hotkey Actions.ahk
#Include ..\Lib\Actions\Modules\Application Actions.ahk

AppHotkeyActions.Register()

AppSpecificHotkey.Set("ahk_exe Notion.exe", ActionIds.Application.NotionSidebarToggle, AppSpecificHotkey.PRIMARY_SHORTCUT)

AppSpecificHotkey.Set("ahk_exe ms-teams.exe", ActionIds.Application.TeamsMicrophoneToggle, AppSpecificHotkey.PRIMARY_SHORTCUT)

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

AppSpecificHotkey.Set("ahk_exe Code.exe", ActionIds.Application.VsCodePrimaryAction, AppSpecificHotkey.PRIMARY_SHORTCUT)
AppSpecificHotkey.Set("ahk_exe Code.exe", ActionIds.Application.VsCodeSecondaryAction, AppSpecificHotkey.SECONDARY_SHORTCUT)



Class AppSpecificHotkey {

    static PRIMARY_SHORTCUT := "#Z"
    static SECONDARY_SHORTCUT := "#!Z"

	static Set(window, actionId, shortcut := this.PRIMARY_SHORTCUT) {
		HotIfWinActive window
		ActionBinding.BindHotkey(shortcut, actionId, "app-hotkeys")
		HotIf
	}
}
