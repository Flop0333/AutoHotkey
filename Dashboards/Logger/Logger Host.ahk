#SingleInstance Force
Persistent(true)
#Include Logger.ahk

TraySetIcon("..\..\Lib\icon.png")

try {
	myLogger := LoggerPopup()
	FileAppend(A_TickCount " LoggerPopup() constructed OK, hwnd=" myLogger.Gui.Hwnd "`n", A_Temp "\ahk_logger_debug.log", "UTF-8")
} catch as err {
	FileAppend(A_TickCount " LoggerPopup() CRASHED: " err.Message " at " err.File ":" err.Line "`nStack: " (err.HasProp("Stack") ? err.Stack : "n/a") "`n", A_Temp "\ahk_logger_debug.log", "UTF-8")
	throw err
}

SetTimer(() => FileAppend(A_TickCount " alive check, hwnd valid=" (DllCall("IsWindow", "Ptr", myLogger.Gui.Hwnd) ? 1 : 0) "`n", A_Temp "\ahk_logger_debug.log", "UTF-8"), -3000)

