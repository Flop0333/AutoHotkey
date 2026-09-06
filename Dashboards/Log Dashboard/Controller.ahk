#Include ..\..\Lib\Core.ahk
#Include ..\..\Lib\Core\WebView.ahk

Class LogDashboard extends WebViewToo {
	static WIN_TITLE := "AutoHotkey Error Logger - Log Dashboard"
	static SHOW_OPTIONS := Format("w{} h{}", Round(A_ScreenWidth * 0.85), Round(A_ScreenHeight * 0.75))

	__New() {
		super.__New()
		this.Gui.Title := LogDashboard.WIN_TITLE
		this.Gui.OnEvent("Close", (*) => this.Hide())
		this.SetVirtualHostNameToFolderMapping("app.local", Paths.dashboards "\Log Dashboard\User Interface", 0) ; block cors error, allow loading local files
		this.Load("http://app.local/index.html")
		this.AddCallbackToScript("GetLogEntries", (*) => this.GetLogEntriesForWeb())
		this.AddCallbackToScript("SetClipboard", (webview, text) => A_Clipboard := text)
		this.AddCallbackToScript("LogTestMessage", (webview, severity) => this.LogTestMessage(severity))
		this.AddCallbackToScript("GetGitStatus", (*) => this.GetGitStatusForWeb())
	}

	Show() => super.Show(LogDashboard.SHOW_OPTIONS, LogDashboard.WIN_TITLE)
	InitializeHidden() => super.Show("Hide " LogDashboard.SHOW_OPTIONS, LogDashboard.WIN_TITLE)

	Close() => this.Hide()

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
		"info", "Test info message",
		"warning", "Test warning message",
		"error", "Test error message"
	)

	LogTestMessage(severity) {
		message := LogDashboard.TestMessages.Get(severity, "Test message")
		switch severity {
			case "info": LogAndNotifyInfo(message)
			case "warning": LogAndNotifyWarning(message)
			case "error": LogAndNotifyError(message)
			default: AppendLogEntry(severity, message)
		}
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
