#Include ..\..\Lib\Core.ahk
#Include ..\..\Lib\Core\WebView.ahk

Class LogDashboard extends WebViewToo {
	static WIN_TITLE := "Log Dashboard"
	static SHOW_OPTIONS := Format("w{} h{}", 900, Round(A_ScreenHeight * 0.75))

	__New() {
		super.__New()
		this.SetVirtualHostNameToFolderMapping("app.local", USER_INTERFACE_PATH, 0) ; block cors error, allow loading local files
		this.Load("http://app.local/index.html")
		this.AddCallbackToScript("GetLogEntries", (*) => this.GetLogEntriesForWeb())

		this.Show()
		; this.OpenDevToolsWindow()
	}

	Show() => super.Show(LogDashboard.SHOW_OPTIONS, LogDashboard.WIN_TITLE)

	GetLogEntriesForWeb() {
		entries := []
		logFile := Paths.autohotkey "\Logs\errors.log"
		if !FileExist(logFile)
			return JSON.Dump(entries)

		for line in StrSplit(FileRead(logFile, "UTF-8"), "`n", "`r") {
			if (Trim(line) = "")
				continue
			try entries.Push(JSON.parse(line))
		}
		return JSON.Dump(entries)
	}
}
