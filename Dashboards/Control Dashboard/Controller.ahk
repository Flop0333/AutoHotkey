#Include ..\..\Lib\Core\OnError.ahk
#Include ..\..\Lib\Core\Paths.ahk
#Include ..\..\Lib\Extensions\Json.ahk
#Include ..\..\Lib\Core\WebView.ahk
#Include ..\..\Apps Integrated\Suite Control\Suite Control.ahk
#Include ..\..\Apps Integrated\Suite Control\Startup Scripts.ahk
#Include ..\..\Profiles\Profile Manager.ahk
; The catalog is what the Health section counts against, but a Secret's own
; methods reach for the file manager and the prompt UI, so the whole facade has
; to be present or those references fail at load time - which is exactly what
; broke the three logging hosts when only the catalog was included here.
#Include ..\..\Secrets\Secrets Service.ahk
#Include Test Run Status.ahk

Class ControlDashboard extends WebViewToo {
	static WIN_TITLE := "AutoHotkey Control Dashboard"
	static INITIALIZING_TITLE := "AutoHotkey Control Dashboard - Initializing"
	static SHOW_OPTIONS := Format("w{} h{}", Round(A_ScreenWidth * 0.85), Round(A_ScreenHeight * 0.75))
	; Written by Tests\Invoke-AllTests.ps1; the Tests section will read more of it.
	static TEST_STATUS_FILE := Paths.autohotkey "\Logs\test-run-status.json"
	static TEST_RUNNER_SCRIPT := Paths.autohotkey "\Tests\Invoke-AllTests.ps1"
	static TEST_HISTORY_FILE := Paths.autohotkey "\Logs\test-run-history.log"
	static SECRETS_FILE := Paths.autohotkey "\Secrets\My Secrets.json"
	; Evergreen WebView2 runtime, as registered by its installer.
	static WEBVIEW2_VERSION_KEYS := [
		"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}",
		"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}",
		"HKEY_CURRENT_USER\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}"
	]

	__New() {
		super.__New()
		; Processor use is a rate between two samples; these hold the last one.
		this._cpuTicks := 0
		this._cpuSampledAt := 0
		; Process start times come from WMI, so they are read once per process
		; instead of on every poll of the Processes section.
		this._startTimes := Map()
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
		this.AddCallbackToScript("GetTestRuns", (*) => this.GetTestRunsForWeb())
		this.AddCallbackToScript("GetHealth", (*) => this.GetHealthForWeb())
		this.AddCallbackToScript("GetProcesses", (*) => this.GetProcessesForWeb())
		this.AddCallbackToScript("GetProfiles", (*) => this.GetProfilesForWeb())
		this.AddCallbackToScript("RequestProfile", (webview, displayName) => this.RequestProfile(displayName))
		; Scripts are addressed by process id, never by path: the page names a
		; process, and this side decides which script that is.
		this.AddCallbackToScript("RestartScript", (webview, processId) => this.RestartScript(processId))
		this.AddCallbackToScript("StartExpectedScript", (webview, scriptName) => this.StartExpectedScript(scriptName))
		this.AddCallbackToScript("StopScript", (webview, processId) => this.StopScript(processId))
		this.AddCallbackToScript("OpenLogArchive", (*) => this.OpenLogArchive())
		this.AddCallbackToScript("OpenLogFolder", (*) => this.OpenLogFolder())
		this.AddCallbackToScript("OpenRepository", (*) => this.OpenRepository())
	}

	OpenLogArchive() {
		DirCreate(ErrorLogArchiveDirectory())
		return this.ReportOutcome(() => Run('explorer.exe "' ErrorLogArchiveDirectory() '"'))
	}

	OpenLogFolder() {
		DirCreate(ErrorLogDirectory())
		return this.ReportOutcome(() => Run('explorer.exe "' ErrorLogDirectory() '"'))
	}

	OpenRepository() {
		return this.ReportOutcome(() => Run('explorer.exe "' Paths.autohotkey '"'))
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
			"tests", this.LastTestRun(this.SessionStartedAt(logState["sessionId"]))
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
		sessionStartedAt := this.SessionStartedAt(sessionId)
		return sessionStartedAt = "" ? "" : DateDiff(A_Now, sessionStartedAt, "Seconds")
	}

	SessionStartedAt(sessionId) {
		if !RegExMatch(sessionId, "^(\d{8})-(\d{6})", &sessionStart)
			return ""
		return sessionStart[1] sessionStart[2]
	}

	; Scoped to this suite session: a pass or fail from an earlier session is
	; not this session's result, and reporting it would tell the user the tests
	; ran when they have not.
	LastTestRun(sessionStartedAt) {
		return TestRunStatus.Read(ControlDashboard.TEST_STATUS_FILE, sessionStartedAt)
	}

	; --- Profiles -----------------------------------------------------------

	; Device names are read here, on demand, rather than when this process
	; starts: the work profile's names come from a secret, and a viewer process
	; should not touch the secrets file just by existing.
	GetProfilesForWeb() {
		profiles := []
		for profile in ProfileManager.allProfiles {
			profiles.Push(Map(
				"displayName", profile.displayName,
				"devices", this.DeviceNames(profile),
				"isCurrent", profile = ProfileManager.current ? 1 : 0
			))
		}
		return JSON.Dump(Map(
			"computerName", A_ComputerName,
			"current", ProfileManager.current.displayName,
			"origin", this.CurrentProfileOrigin(),
			"profiles", profiles
		))
	}

	DeviceNames(profile) {
		names := []
		try {
			for device in profile.deviceName
				if (Trim(device) != "")
					names.Push(device)
		}
		return names
	}

	; Auto-detection matches the computer name against a profile's devices, so
	; a current profile that this machine's name does not match can only have
	; been chosen by hand.
	CurrentProfileOrigin() {
		for device in this.DeviceNames(ProfileManager.current)
			if InStr(A_ComputerName, device)
				return "detected"
		return "chosen"
	}

	; Records the profile for the next start. The page reloads the suite after
	; this succeeds, so a failure to save is reported before anything restarts.
	RequestProfile(displayName) {
		return this.ReportOutcome(() => this.RequestProfileByName(displayName))
	}

	RequestProfileByName(displayName) {
		for profile in ProfileManager.allProfiles {
			if (profile.displayName != displayName)
				continue
			if !ProfileManager.RequestProfile(profile)
				throw Error("The profile could not be saved on this machine")
			return
		}
		throw Error("Unknown profile: " displayName)
	}

	; --- Processes ----------------------------------------------------------

	GetProcessesForWeb() {
		processes := []
		startTimes := Map()
		runningScripts := SuiteControl.ListRunningScripts(false)
		for script in runningScripts {
			if this._startTimes.Has(script.processId)
				startedAt := this._startTimes[script.processId]
			else
				startedAt := SuiteControl.GetProcessStartTime(script.processId)
			startTimes[script.processId] := startedAt

			processes.Push(Map(
				"name", script.name,
				"path", script.path,
				"processId", script.processId,
				"uptimeSeconds", startedAt = "" ? "" : DateDiff(A_Now, startedAt, "Seconds"),
				"belongsToSuite", script.belongsToSuite ? 1 : 0,
				"isDashboard", script.processId = this.CurrentProcessId() ? 1 : 0,
				"isLoggingHost", this.IsLoggingHost(script.path) ? 1 : 0
			))
		}
		for scriptPath in SuiteControl.FindMissingScripts(runningScripts, SuiteStartupScripts()) {
			SplitPath(scriptPath, &scriptName)
			processes.Push(Map("name", scriptName, "path", scriptPath, "processId", 0,
				"uptimeSeconds", "", "belongsToSuite", 1, "isDashboard", 0,
				"isLoggingHost", 0, "isMissing", 1))
		}
		; Drop the processes that are gone rather than growing the map forever.
		this._startTimes := startTimes
		return JSON.Dump(processes)
	}

	ShowSection(sectionName) {
		allowed := Map("overview", 1, "processes", 1, "logs", 1, "tests", 1, "profiles", 1, "health", 1)
		if allowed.Has(sectionName)
			this.ExecuteScript("window.controlDashboardShell && window.controlDashboardShell.show(" JSON.Dump(sectionName) ")")
	}

	; The Logger popup is the suite's notification surface; stopping it leaves
	; the suite unable to tell the user anything until the next reload.
	IsLoggingHost(scriptPath) {
		SplitPath(scriptPath, &scriptName)
		return scriptName = "Logger Host.ahk"
	}

	CurrentProcessId() => DllCall("GetCurrentProcessId", "UInt")

	RestartScript(processId) {
		return this.ReportOutcome(() => this.RestartScriptByProcessId(Integer(processId)))
	}

	RestartScriptByProcessId(processId) {
		for script in SuiteControl.ListRunningScripts(false) {
			if (script.processId != processId)
				continue
			SuiteControl.RestartScript(script.path)
			return
		}
		throw Error("That script is no longer running")
	}

	StartExpectedScript(scriptName) {
		return this.ReportOutcome(() => this.StartExpectedScriptByName(scriptName))
	}

	StartExpectedScriptByName(scriptName) {
		for scriptPath in SuiteStartupScripts() {
			SplitPath(scriptPath, &expectedName)
			if (expectedName = scriptName) {
				Run('"' A_AhkPath '" "' scriptPath '"')
				return
			}
		}
		throw Error("That script is not in the suite startup list")
	}

	StopScript(processId) {
		return this.ReportOutcome(() => this.StopScriptByProcessId(Integer(processId)))
	}

	StopScriptByProcessId(processId) {
		if (processId = this.CurrentProcessId())
			throw Error("The dashboard cannot stop its own process - use Exit suite instead")
		if !SuiteControl.StopScript(processId)
			throw Error("The script did not stop")
	}

	; --- Health -------------------------------------------------------------

	; Everything the Health section reports. Only this section asks for it, so
	; the processor sample and the registry and secrets lookups happen while it
	; is on screen rather than on every poll tick.
	GetHealthForWeb() {
		scripts := SuiteControl.ListRunningScripts(false)
		return JSON.Dump(Map(
			"autoHotkey", Map("version", A_AhkVersion, "path", A_AhkPath),
			"webView2", this.WebView2Runtime(),
			"cpu", this.SampleCpu(scripts),
			"paths", Map(
				"repository", Paths.autohotkey,
				"logs", ErrorLogDirectory(),
				"archive", ErrorLogArchiveDirectory(),
				"logDirectoryOverride", EnvGet("AUTOHOTKEY_LOG_DIR")
			),
			"session", Map(
				"id", GetLogSessionId(),
				"archivedSessions", this.ArchivedSessionCount()
			),
			"secrets", this.SecretsState()
		))
	}

	; Processor time is a rate, so it needs two samples. The first call after
	; the section opens establishes the baseline and reports no percentage yet.
	SampleCpu(scripts) {
		ticks := SuiteControl.TotalCpuTicks(scripts)
		sampledAt := A_TickCount
		percent := ""
		if (this._cpuSampledAt) {
			percent := SuiteControl.CpuPercentFromTicks(ticks - this._cpuTicks,
				sampledAt - this._cpuSampledAt, SuiteControl.ProcessorCount())
		}
		this._cpuTicks := ticks
		this._cpuSampledAt := sampledAt
		return Map(
			"percent", percent,
			"processes", scripts.Length,
			"processorCount", SuiteControl.ProcessorCount()
		)
	}

	; The page is rendered by WebView2, so the runtime is present whether or not
	; its version can be read; only the version is ever in doubt.
	WebView2Runtime() {
		for versionKey in ControlDashboard.WEBVIEW2_VERSION_KEYS {
			try {
				version := RegRead(versionKey, "pv", "")
				if (version != "")
					return Map("status", "ok", "version", version)
			}
		}
		return Map("status", "unknown", "version", "")
	}

	ArchivedSessionCount() {
		archived := 0
		if !DirExist(ErrorLogArchiveDirectory())
			return archived
		loop files ErrorLogArchiveDirectory() "\errors-*.log", "F"
			archived += 1
		return archived
	}

	; Counts only. Secret values never reach the page, and neither do the key
	; names: the catalog is tracked, but what a machine has filled in is not.
	SecretsState() {
		catalogKeys := SecretsCatalog.Count
		if !FileExist(ControlDashboard.SECRETS_FILE)
			return Map("status", "missing", "catalogKeys", catalogKeys, "keysWithValue", 0)
		try secrets := JSON.parse(FileRead(ControlDashboard.SECRETS_FILE, "UTF-8"))
		catch
			return Map("status", "invalid", "catalogKeys", catalogKeys, "keysWithValue", 0)
		if !(secrets is Map)
			return Map("status", "invalid", "catalogKeys", catalogKeys, "keysWithValue", 0)

		keysWithValue := 0
		for key, value in secrets {
			if !SecretsCatalog.Has(key)
				continue
			if (value is Array ? value.Length > 0 : Trim(String(value)) != "")
				keysWithValue += 1
		}
		status := keysWithValue = catalogKeys ? "ok" : "partial"
		return Map("status", status, "catalogKeys", catalogKeys, "keysWithValue", keysWithValue)
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
		return this.ReportOutcome(() => this.StartTestRun(testRunner))
	}

	; One runner at a time: a second run would race the first for the status and
	; history files it writes.
	StartTestRun(testRunner) {
		if (this.LastTestRun("").Get("status", "") = "running")
			throw Error("A test run is already in progress")
		Run(testRunner, , "Hide")
	}

	; Status and history in one read, both scoped to this suite session.
	GetTestRunsForWeb() {
		sessionStartedAt := this.SessionStartedAt(GetLogSessionId())
		return JSON.Dump(Map(
			"status", this.LastTestRun(sessionStartedAt),
			"runs", TestRunStatus.ReadRuns(ControlDashboard.TEST_HISTORY_FILE, sessionStartedAt)
		))
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
