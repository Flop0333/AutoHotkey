#Include App.ahk
#Include ..\Core\Paths.ahk

class VsCode extends App {
	static __New() => this.Init(
		winTitle := "Visual Studio Code",
		ahk_exe := "Code.exe",
		path := "C:\Users\" A_UserName "\AppData\Local\Programs\Microsoft VS Code Insiders\Code - Insiders.exe"
	)

	static openAutoHotkey() => VsCode.OpenFile(Paths.autohotkey)
	static openPersonalOS() => VsCode.OpenFile(Paths.personalOS)
	
	; Windows and AutoHotkey need each argument wrapped in quotes when it contains spaces,
	static openFile(filePath) => RunWait('"' . this.ahk_exe . '" "' . filePath . '"') WinMaximize("ahk_exe Code.exe")
	
	static OpenWorkspace(workspacePath) {
		Run('explorer.exe "' . workspacePath . '"')
		WinWait("ahk_exe Code.exe")
		WinMaximize("ahk_exe Code.exe")
	}
}
