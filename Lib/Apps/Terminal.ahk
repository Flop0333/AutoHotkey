#Include <Apps\App>

class Terminal extends App {
	static __New() => this.Init("Windows Terminal", "WindowsTerminal.exe", "wt.exe")

	static DeleteWord() => Send("^w")
}