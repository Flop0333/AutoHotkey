#SingleInstance Force
Persistent(true)

#Include ..\..\Lib\Core\OnError.ahk
#Include ..\..\Lib\Core\Paths.ahk
InstallGlobalErrorHandler()

TraySetIcon(Paths.autoHotkeyIcon)

myTestDashboard := TestDashboard()
myTestDashboard.InitializeHidden()

#Include Test Dashboard.ahk
