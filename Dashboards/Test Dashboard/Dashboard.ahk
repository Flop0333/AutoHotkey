#SingleInstance Force
Persistent(true)

TraySetIcon(Paths.autoHotkeyIcon)

myTestDashboard := TestDashboard()
myTestDashboard.InitializeHidden()

#Include Test Dashboard.ahk
