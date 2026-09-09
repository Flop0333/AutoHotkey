#SingleInstance Force
Persistent(true)
#Include ..\..\Lib\Core\OnError.ahk
#Include Logger.ahk

InstallGlobalErrorHandler()
TraySetIcon("..\..\Lib\icon.png")

myLogger := LoggerPopup()

