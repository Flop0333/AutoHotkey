Class Paths {

	static autohotkey 	:= Paths._ResolveBasePath()

	static appsIntegrated	:= this.autohotkey "\Apps Integrated"
	static appsStandalone	:= this.autohotkey "\Apps Standalone"
	static dashboards		:= this.autohotkey "\Dashboards"
	static profiles			:= this.autohotkey "\Profiles"
	static startup			:= this.autohotkey "\Startup"
	static lib				:= this.autohotkey "\Lib"

	static _username := "C:\Users\" A_UserName
	static vsCode := A_AppData "\..\Local\Programs\Microsoft VS Code\Code.exe"
	static windows := {
		desktop 	: A_Desktop,
		documents 	: A_MyDocuments,
		music 		: this._username "\music",
		videos 		: this._username "\videos",
		pictures 	: this._username "\pictures",
		downloads 	: this._username "\downloads",
		LocalAppData: this._username "\AppData\Local"
	}	

	static _ResolveBasePath() {
		envBase := EnvGet("AUTOHOTKEY_BASE")
		if (envBase != "")
			return RTrim(envBase, "\\/")

		; Default to repo root based on this file location: <base>\Lib\Core\Paths.ahk
		SplitPath(A_LineFile, , &coreDir)
		SplitPath(coreDir, , &libDir)
		SplitPath(libDir, , &baseDir)
		if (DirExist(baseDir))
			return baseDir

		; Fallback: assume this script is in <base>\Startup
		SplitPath(A_ScriptDir, , &scriptDir)
		SplitPath(scriptDir, , &fallbackBase)
		return fallbackBase
	}
}