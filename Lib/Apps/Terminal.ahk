#Include App.ahk

class Terminal extends App {
	static __New() => App.Init("Windows Terminal", "WindowsTerminal.exe", "wt.exe")

	static DeleteWord() => Send("^w")
}