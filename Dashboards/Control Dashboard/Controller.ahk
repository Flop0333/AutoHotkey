#Include ..\..\Lib\Core\OnError.ahk
#Include ..\..\Lib\Core\Paths.ahk
#Include ..\..\Lib\Extensions\Json.ahk
#Include ..\..\Lib\Core\WebView.ahk
#Include ..\..\Apps Integrated\Suite Control\Suite Control.ahk

Class ControlDashboard extends WebViewToo {
	static WIN_TITLE := "AutoHotkey Control Dashboard"
	static INITIALIZING_TITLE := "AutoHotkey Control Dashboard - Initializing"
	static SHOW_OPTIONS := Format("w{} h{}", Round(A_ScreenWidth * 0.85), Round(A_ScreenHeight * 0.75))
	; Written by Tests\Invoke-AllTests.ps1; the Tests section will read more of it.
	static TEST_STATUS_FILE := Paths.autohotkey "\Logs\test-run-status.json"
	static TEST_RUNNER_SCRIPT := Paths.autohotkey "\Tests\Invoke-AllTests.ps1"

	__New() {
		super.__New()
		this.Gui.Title := ControlDashboard.INITIALIZING_TITLE
		this.Gui.OnEvent("Close", (*) => this.Hide())
		this.SetVirtualHostNameToFolderMapping("app.local", Paths.dashboards "\Control Dashboard\User Interface", 0) ; block cors error, allow loading local files
		this.Load("http://app.local/index.html")
		this.AddCallbackToScript("GetSuiteStatus", (*) => this.GetSuiteStatusForWeb())
		this.AddCallbackToScript("GetLogEntries", (*) => this.GetLogEntriesForWeb())
		this.AddCallbackToScript("SetClipboard", (webview, text) => A_Clipboard := text)
		this.AddCallbackToScript("LogTestMessage", (webview, severity) => this.LogTestMessage(severity))
		this.AddCallbackToScript("GetGitStatus", (*) => this.GetGitStatusForWeb())
		; Actions. Each one is a named callback: no path, command line, or script
		; text ever crosses the bridge from the web layer.
		this.AddCallbackToScript("ReloadSuite", (*) => this.ReloadSuite())
		this.AddCallbackToScript("ExitSuite", (*) => this.ExitSuite())
		this.AddCallbackToScript("RunAllTests", (*) => this.RunAllTests())
		this.AddCallbackToScript("OpenLogArchive", (*) => this.OpenLogArchive())
	}

	OpenLogArchive() {
		DirCreate(ErrorLogArchiveDirectory())
		Run('explorer.exe "' ErrorLogArchiveDirectory() '"')
	}

	Show() => super.Show(ControlDashboard.SHOW_OPTIONS, ControlDashboard.WIN_TITLE)

	InitializeHidden() {
		; WIN_TITLE is also the cross-process readiness signal. Publish it only
		; after the initial Hide has completed so a waiting caller cannot show
		; this window just before the host hides it again.
		super.Show("Hide " ControlDashboard.SHOW_OPTIONS, ControlDashboard.INITIALIZING_TITLE)
		this.Gui.Title := ControlDashboard.WIN_TITLE
	}

	Close() => this.Hide()

	; Everything the status strip shows, in one read: the log file is opened once
	; under the shared logging lock instead of once per value.
	GetSuiteStatusForWeb() {
		logState := ReadLogState()
		return JSON.Dump(Map(
			"profile", this.CurrentProfileName(),
			"uptimeSeconds", this.SessionUptimeSeconds(logState["sessionId"]),
			"entryCount", logState["entries"].Length,
			"runningScripts", SuiteControl.ListRunningScripts(false).Length,
			"unread", GetUnreadLogCounts(logState["entries"], logState["readEntryCount"]),
			"tests", this.LastTestRun()
		))
	}

	; The display name only. Reading it from the profile ini keeps this viewer
	; process out of the secrets stack that Profile Manager needs for device
	; matching; the Profiles section adds the full list when it needs one.
	CurrentProfileName() {
		try return Trim(IniRead(Paths.profileIniFile, "Profile", "Current", ""))
		return ""
	}

	; The log session starts with the suite, so its id doubles as the suite's
	; start time: "yyyyMMdd-HHmmss-<pid>-<tick>-<sequence>".
	SessionUptimeSeconds(sessionId) {
		if !RegExMatch(sessionId, "^(\d{8})-(\d{6})", &sessionStart)
			return ""
		return DateDiff(A_Now, sessionStart[1] sessionStart[2], "Seconds")
	}

	LastTestRun() {
		if !FileExist(ControlDashboard.TEST_STATUS_FILE)
			return Map("status", "unknown")
		try return JSON.parse(FileRead(ControlDashboard.TEST_STATUS_FILE, "UTF-8"))
		return Map("status", "unknown")
	}

	GetLogEntriesForWeb() {
		return JSON.Dump(ReadLogEntries())
	}

	; The page confirms first, so these skip the service's own prompt. Neither
	; returns: the calling process is this dashboard.
	ReloadSuite() => SuiteControl.ReloadSuite(false)

	ExitSuite() => SuiteControl.ExitSuite(false)

	RunAllTests() {
		testRunner := 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' ControlDashboard.TEST_RUNNER_SCRIPT '"'
		return this.ReportOutcome(() => Run(testRunner, , "Hide"))
	}

	; An action running in a hidden process must not fail silently: report the
	; outcome so the page can show it.
	ReportOutcome(work) {
		try {
			work.Call()
			return JSON.Dump(Map("ok", 1))
		} catch as actionError {
			return JSON.Dump(Map("ok", 0, "error", actionError.Message))
		}
	}

	static TestMessages := Map(
		"info", "Test info message",
		"warning", "Test warning message",
		"error", "Test error message"
	)

	LogTestMessage(severity) {
		message := ControlDashboard.TestMessages.Get(severity, "Test message")
		return this.ReportOutcome(() => this.WriteTestMessage(severity, message))
	}

	WriteTestMessage(severity, message) {
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
