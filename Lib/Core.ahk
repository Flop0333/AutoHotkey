#Requires Autohotkey v2
#SingleInstance Force
#NoTrayIcon

; Core
#Include Core\Paths.ahk
#Include Core\Links.ahk
#Include ..\Profiles\Profile Manager.ahk
#Include ..\Secrets\Secrets Service.ahk

; Extensions
#Include Extensions\Array.ahk
#Include Extensions\Dark Gui.ahk
#Include Extensions\Dark MsgBox.ahk
#Include Extensions\Dark ToolTip.ahk
#Include Extensions\Json.ahk
#Include Extensions\Singleton.ahk
#Include Extensions\String.ahk
#Include Extensions\WinHttpRequest.ahk
#Include Extensions\Win.ahk

; Helpers
#Include Helpers\Capslock.ahk
#Include Helpers\ClipSend.ahk
#Include Helpers\Counter.ahk
#Include Helpers\System.ahk
#Include Helpers\Wait.ahk

; Tools
#Include Tools\Desktops DLL Library\Desktops DLL Library.ahk
#Include Tools\Cmd.ahk
#Include Tools\Info.ahk
#Include Tools\IniService.ahk
#Include Tools\InternetSearch.ahk
#Include Tools\Multiple Press Detection.ahk
#Include Tools\User Input.ahk
#Include Tools\Web.ahk