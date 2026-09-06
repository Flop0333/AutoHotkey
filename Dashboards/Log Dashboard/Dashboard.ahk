#SingleInstance Force
Persistent(true)

TraySetIcon(Paths.autoHotkeyIcon)

myLogDashboard := LogDashboard()
myLogDashboard.InitializeHidden()

#Include Log Dashboard.ahk
