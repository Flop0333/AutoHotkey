#Include ..\..\Lib\Core.ahk
#Include ..\..\Lib\Core\WebView.ahk

Class LogDashboard extends WebViewToo {
	static WIN_TITLE := "Log Dashboard"
	static SHOW_OPTIONS := Format("w{} h{}", Round(A_ScreenWidth * 0.85), Round(A_ScreenHeight * 0.75))

	__New() {
		super.__New()
		this.SetVirtualHostNameToFolderMapping("app.local", USER_INTERFACE_PATH, 0) ; block cors error, allow loading local files
		this.Load("http://app.local/index.html")
		this.AddCallbackToScript("GetLogEntries", (*) => this.GetLogEntriesForWeb())
		this.AddCallbackToScript("SetClipboard", (webview, text) => A_Clipboard := text)
		this.AddCallbackToScript("LogTestMessage", (webview, severity) => this.LogTestMessage(severity))
		this.AddCallbackToScript("GetGitStatus", (*) => this.GetGitStatusForWeb())

		this.Show()
		; this.OpenDevToolsWindow()
	}

	Show() => super.Show(LogDashboard.SHOW_OPTIONS, LogDashboard.WIN_TITLE)

	GetLogEntriesForWeb() {
		entries := []
		if !FileExist(ErrorLogFile())
			return JSON.Dump(entries)

		for line in StrSplit(FileRead(ErrorLogFile(), "UTF-8"), "`n", "`r") {
			if (Trim(line) = "")
				continue
			try entries.Push(JSON.parse(line))
		}
		return JSON.Dump(entries)
	}

	static TestMessages := Map(
		"error", "Test error message",
		"info", "Test info message",
		"success", "Test success message"
	)

	LogTestMessage(severity) {
		LogMessage(severity, LogDashboard.TestMessages.Get(severity, "Test message"))
	}

	GetGitStatusForWeb() {
		branch := "", ahead := 0, behind := 0
		try {
			shell := ComObject("WScript.Shell")
			exec := shell.Exec(A_ComSpec ' /C cd /d "' Paths.autohotkey '" && git status -sb --porcelain=v1')
			while !exec.Status
				Sleep(10)
			firstLine := StrSplit(exec.StdOut.ReadAll(), "`n")[1]
			if RegExMatch(firstLine, "^## ([^.\s]+)", &m)
				branch := m[1]
			if RegExMatch(firstLine, "ahead (\d+)", &m)
				ahead := m[1]
			if RegExMatch(firstLine, "behind (\d+)", &m)
				behind := m[1]
		}
		return JSON.Dump(Map("branch", branch, "ahead", ahead, "behind", behind))
	}
}
