; KillAllAHkProcesses()

KillAllAHkProcesses() {
    result := MsgBox("Kill all AutoHotkey processes?", "Kill AutoHotkey", "YesNo")
    if (result = "No")
        return

    DetectHiddenWindows true
	SetTitleMatchMode 'RegEx'
	HWNDs := WinGetList('ahk_exe AutoHotkey')
	For HWND in HWNDs
	{
		if HWND != A_ScriptHwnd
			try
				WinKill(HWND)
	}
	ExitApp
}
