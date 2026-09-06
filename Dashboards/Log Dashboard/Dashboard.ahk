#SingleInstance Force
Persistent(true)

TraySetIcon(Paths.autoHotkeyIcon)

try {
	myLogDashboard := LogDashboard()
	myLogDashboard.InitializeHidden()
	FileAppend(A_TickCount " LogDashboard() constructed+hidden OK, hwnd=" myLogDashboard.Gui.Hwnd "`n", A_Temp "\ahk_logger_debug.log", "UTF-8")
} catch as err {
	FileAppend(A_TickCount " LogDashboard() CRASHED: " err.Message " at " err.File ":" err.Line "`n", A_Temp "\ahk_logger_debug.log", "UTF-8")
	throw err
}

#Include Log Dashboard.ahk
