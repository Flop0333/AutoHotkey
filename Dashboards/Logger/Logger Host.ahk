#SingleInstance Force
Persistent(true)
#Include ..\..\Lib\Core\OnError.ahk
#Include Logger.ahk

OnError(HandleUnhandledError)
TraySetIcon("..\..\Lib\icon.png")

myLogger := LoggerPopup()

