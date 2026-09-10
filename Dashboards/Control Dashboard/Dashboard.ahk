#SingleInstance Force
Persistent(true)
#Include ..\..\Lib\Core\OnError.ahk
#Include ..\..\Lib\Core\Paths.ahk

TraySetIcon(Paths.autoHotkeyIcon)

myControlDashboard := ControlDashboard()
myControlDashboard.InitializeHidden()

#Include Control Dashboard.ahk
