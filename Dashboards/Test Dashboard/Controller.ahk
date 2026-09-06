#Include ..\..\Lib\Core.ahk
#Include ..\..\Lib\Core\WebView.ahk

Class TestDashboard extends WebViewToo {
	static WIN_TITLE := "AutoHotkey Test Dashboard"
	static SHOW_OPTIONS := Format("w{} h{}", Round(A_ScreenWidth * 0.7), Round(A_ScreenHeight * 0.7))
	static RUNNER_SCRIPT := Paths.autohotkey "\Tests\Invoke-AllTests.ps1"
	static HISTORY_FILE := Paths.autohotkey "\Logs\test-run-history.log"
	static STATUS_FILE := Paths.autohotkey "\Logs\test-run-status.json"

	__New() {
		super.__New()
		this._ClearHistory()
		this.Gui.Title := TestDashboard.WIN_TITLE
		this.Gui.OnEvent("Close", (*) => this.Hide())
		this.SetVirtualHostNameToFolderMapping("app.local", Paths.dashboards "\Test Dashboard\User Interface", 0) ; block cors error, allow loading local files
		this.Load("http://app.local/index.html")
		this.AddCallbackToScript("GetTestRuns", (*) => this.GetTestRunsForWeb())
		this.AddCallbackToScript("GetStatus", (*) => this.GetStatusForWeb())
		this.AddCallbackToScript("RunTests", (*) => this.RunTests())
		this.AddCallbackToScript("SetClipboard", (webview, text) => A_Clipboard := text)
	}

	Show() => super.Show(TestDashboard.SHOW_OPTIONS, TestDashboard.WIN_TITLE)
	InitializeHidden() => super.Show("Hide " TestDashboard.SHOW_OPTIONS, TestDashboard.WIN_TITLE)

	Close() => this.Hide()

	; Runs are scoped to this dashboard process's lifetime - a fresh instance
	; (one per Dashboard.ahk launch, since #SingleInstance Force means there's
	; only ever one) starts with no history from earlier sessions.
	_ClearHistory() {
		try FileDelete(TestDashboard.HISTORY_FILE)
		try FileDelete(TestDashboard.STATUS_FILE)
	}

	RunTests() {
		Run('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' TestDashboard.RUNNER_SCRIPT '"', , "Hide")
	}

	GetStatusForWeb() {
		if !FileExist(TestDashboard.STATUS_FILE)
			return JSON.Dump(Map("status", "idle"))
		try return FileRead(TestDashboard.STATUS_FILE, "UTF-8")
		return JSON.Dump(Map("status", "idle"))
	}

	GetTestRunsForWeb() {
		runs := []
		if !FileExist(TestDashboard.HISTORY_FILE)
			return JSON.Dump(runs)

		for line in StrSplit(FileRead(TestDashboard.HISTORY_FILE, "UTF-8"), "`n", "`r") {
			if (Trim(line) = "")
				continue
			try runs.Push(JSON.parse(line))
		}
		return JSON.Dump(runs)
	}
}
