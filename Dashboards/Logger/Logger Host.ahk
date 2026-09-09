#SingleInstance Force
Persistent(true)
#Include ..\..\Lib\Core\OnError.ahk
#Include Logger.ahk

TraySetIcon("..\..\Lib\icon.png")

myLogger := LoggerPopup()

