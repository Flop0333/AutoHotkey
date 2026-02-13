#Include App.ahk
#Include ..\Core\Paths.ahk

class VsCode extends App {
	static autohotkeyWorkspace := Paths.autohotkey "\VS Code Workspace.code-workspace"
	static __New() => App.Init(
		winTitle := "Visual Studio Code",
		ahk_exe := "Code.exe",
		path := "C:\Users\" A_UserName "\AppData\Local\Programs\Microsoft VS Code Insiders\Code - Insiders.exe"
	)

	static OpenWorkspace(workspacePath) {
		Run("explorer.exe " workspacePath)
		WinWait("ahk_exe Code.exe")
		WinMaximize("ahk_exe Code.exe")
	}
}
