class System {
	static PowerDown() => Shutdown(1) ; Shutdown: ;0 = Logoff,  1 = Shutdown,  2 = Reboot,  4 = Force,  8 = Power down
	
	static Reboot() => Shutdown(2)

	static Lock() => DllCall("LockWorkStation")

	static Sleep() => DllCall("PowrProf\SetSuspendState", "int", 0, "int", 0, "int", 0)

	static Hibernate() => DllCall("PowrProf\SetSuspendState", "int", 1, "int", 0, "int", 0)

	static SetDisplayToSecondScreenOnly() => Run(A_WinDir "\System32\DisplaySwitch.exe /external")

	static SetDisplayToExtend() => Run(A_WinDir "\System32\DisplaySwitch.exe /extend")

	static KillAllAHkProcesses() {
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
}
