#Include App.ahk

class Teams extends App {
	static __New() => App.Init(
		winTitle := "Microsoft Teams",
		ahk_exe := "Teams.exe"
	)
}