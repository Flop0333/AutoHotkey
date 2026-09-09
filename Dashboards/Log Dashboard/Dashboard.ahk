#SingleInstance Force
Persistent(true)
#Include ..\..\Lib\Core\OnError.ahk
#Include ..\..\Lib\Core\Paths.ahk

TraySetIcon(Paths.autoHotkeyIcon)

myLogDashboard := LogDashboard()
myLogDashboard.InitializeHidden()

#Include Log Dashboard.ahk
