#Requires Autohotkey v2
#SingleInstance Force
#NoTrayIcon

; Core
#Include ..\Secrets\Secrets Service.ahk
#Include ..\Profiles\Profile Manager.ahk
#Include <Core\Paths>
#Include <Core\Links>

; Extensions
#Include <Extensions\Array>
#Include <Extensions\Dark Gui>
#Include <Extensions\Dark MsgBox>
#Include <Extensions\Dark ToolTip>
#Include <Extensions\Json>
#Include <Extensions\Singleton>
#Include <Extensions\String>
#Include <Extensions\WinHttpRequest>
#Include <Extensions\Win>

; Helpers
#Include <Helpers\Capslock>
#Include <Helpers\ClipSend>
#Include <Helpers\Counter>
#Include <Helpers\System>
#Include <Helpers\Wait>

; Tools
#Include <Tools\Desktops DLL Library\Desktops DLL Library>
#Include <Tools\Cmd>
#Include <Tools\Info>
#Include <Tools\IniService>
#Include <Tools\InternetSearch>
#Include <Tools\Multiple Press Detection>
#Include <Tools\User Input>
#Include <Tools\Web>