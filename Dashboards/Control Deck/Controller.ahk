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
#Include Git Repository.ahk

Class ControlDeck extends WebViewToo {
	static WIN_TITLE := "AutoHotkey Control Deck"
	static INITIALIZING_TITLE := "AutoHotkey Control Deck - Initializing"
	static SHOW_OPTIONS := Format("w{} h{}", Round(A_ScreenWidth * 0.85), Round(A_ScreenHeight * 0.75))
	; Written by Tests\Invoke-AllTests.ps1; the Tests section will read more of it.
	static TEST_STATUS_FILE := Paths.autohotkey "\Logs\test-run-status.json"
	static TEST_RUNNER_SCRIPT := Paths.autohotkey "\Tests\Invoke-AllTests.ps1"
	static TEST_HISTORY_FILE := Paths.autohotkey "\Logs\test-run-history.log"
	static SECRETS_FILE := Paths.autohotkey "\Secrets\My Secrets.json"
	; User and machine-wide installs of VS Code, then Insiders. When none is
	; present, the `code` command on PATH is the last resort.
	static VSCODE_EXECUTABLES := [
		Paths.vsCode,
		A_ProgramFiles "\Microsoft VS Code\Code.exe",
		Paths.windows.LocalAppData "\Programs\Microsoft VS Code Insiders\Code - Insiders.exe"
	]
	; Evergreen WebView2 runtime, as registered by its installer.
	static WEBVIEW2_VERSION_KEYS := [
		"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}",
		"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}",
		"HKEY_CURRENT_USER\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}"
	]

	__New() {
		super.__New()
		; A section requested before the page has loaded, held until it asks.
		this._pendingSection := ""
		this._pageReady := false
		; Processor use is a rate between two samples; these hold the last one.
		this._cpuTicks := 0
		this._cpuSampledAt := 0
		; Process start times come from WMI, so they are read once per process
		; instead of on every poll of the Processes section.
		this._startTimes := Map()
		this.repository := GitRepository(Paths.autohotkey)
		this.Gui.Title := ControlDeck.INITIALIZING_TITLE
		this.Gui.OnEvent("Close", (*) => this.Hide())
		; The window is shown and hidden from other processes as well as this
		; one, so visibility is followed through the window message itself.
		OnMessage(0x0018, ObjBindMethod(this, "OnShowWindow")) ; WM_SHOWWINDOW
		this.SetVirtualHostNameToFolderMapping("app.local", Paths.dashboards "\Control Deck\User Interface", 0) ; block cors error, allow loading local files
		; The suite icon lives in Lib, outside the page's folder. Kind 2 lets the page
		; show it as an image while still refusing scripted reads of that folder.
		this.SetVirtualHostNameToFolderMapping("suite.local", Paths.lib, 2)
		this.Load("http://app.local/index.html")
		this.AddCallbackToScript("GetPendingSection", (*) => this.TakePendingSection())
		this.AddCallbackToScript("GetSuiteStatus", (*) => this.GetSuiteStatusForWeb())
		this.AddCallbackToScript("GetLogEntries", (*) => this.GetLogEntriesForWeb())
		this.AddCallbackToScript("MarkLogsRead", (*) => MarkAllLogsRead())
		this.AddCallbackToScript("SetClipboard", (webview, text) => A_Clipboard := text)
		this.AddCallbackToScript("LogTestMessage", (webview, severity) => this.LogTestMessage(severity))
		this.AddCallbackToScript("GetGitStatus", (*) => this.GetGitStatusForWeb())
		this.AddCallbackToScript("GetGitBranches", (*) => this.GetGitBranchesForWeb())
		this.AddCallbackToScript("FetchGit", (*) => this.ReportOutcome(() => this.repository.Fetch()))
		; The branch must be one git listed; the repository checks before switching.
		this.AddCallbackToScript("SwitchGitBranch", (webview, branch, mode, stashMessage) => this.SwitchGitBranch(branch, mode, stashMessage))
		this.AddCallbackToScript("SyncGit", (*) => this.SyncGit())
		; Actions. Each one is a named callback: no path, command line, or script
		; text ever crosses the bridge from the web layer.
		this.AddCallbackToScript("ReloadSuite", (*) => this.ReloadSuite())
		this.AddCallbackToScript("ExitSuite", (*) => this.ExitSuite())
		this.AddCallbackToScript("RunAllTests", (*) => this.RunAllTests())
		this.AddCallbackToScript("GetTestRuns", (*) => this.GetTestRunsForWeb())
		this.AddCallbackToScript("GetHealth", (*) => this.GetHealthForWeb())
		this.AddCallbackToScript("GetSecretsState", (*) => JSON.Dump(this.SecretsState()))
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
		this.AddCallbackToScript("OpenRepositoryInVsCode", (*) => this.OpenRepositoryInVsCode())
		this.AddCallbackToScript("OpenSecretsInVsCode", (*) => this.OpenSecretsInVsCode())
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

	OpenRepositoryInVsCode() {
		return this.ReportOutcome(() => this.StartVsCode(Paths.autohotkey))
	}

	; The repository is passed along with the file, so the file opens in the
	; repository's window rather than in a stray one.
	OpenSecretsInVsCode() {
		return this.ReportOutcome(() => this.StartVsCodeOnSecrets())
	}

	StartVsCodeOnSecrets() {
		if !FileExist(ControlDeck.SECRETS_FILE)
			throw Error("There is no local secrets file yet - start the suite once to create it")
		this.StartVsCode(Paths.autohotkey, ControlDeck.SECRETS_FILE)
	}

	; Not VsCode.OpenFile: that waits for Code.exe to exit, which never happens
	; when it is the first window, and would hang this host.
	StartVsCode(targets*) {
		arguments := ""
		for target in targets
			arguments .= ' "' target '"'
		for executable in ControlDeck.VSCODE_EXECUTABLES {
			if FileExist(executable) {
				Run('"' executable '"' arguments)
				return
			}
		}
		; `code` is a batch file, so it needs a shell; the shell's exit code is
		; the only way to tell that it was not found.
		if RunWait(A_ComSpec ' /C code' arguments, , "Hide")
			throw Error("VS Code is not installed, or its code command is not on PATH")
	}

	Show() => super.Show(ControlDeck.SHOW_OPTIONS, ControlDeck.WIN_TITLE)

	InitializeHidden() {
		; WIN_TITLE is also the cross-process readiness signal. Publish it only
		; after the initial Hide has completed so a waiting caller cannot show
		; this window just before the host hides it again.
		super.Show("Hide " ControlDeck.SHOW_OPTIONS, ControlDeck.INITIALIZING_TITLE)
		; A window that starts hidden never sends WM_SHOWWINDOW for it, so the
		; page is told here. It still loads, ready for the first show.
		this.IsVisible := false
		this.Gui.Title := ControlDeck.WIN_TITLE
	}

	; WebView2 passes this on to the page as document.hidden, which pauses its
	; one-second poll: the dashboard now runs from startup, and a hidden window
	; has nothing to keep current. Returns nothing so Windows still handles
	; the message.
	OnShowWindow(wParam, lParam, msg, hwnd) {
		if (hwnd = this.Gui.Hwnd)
			this.IsVisible := wParam ? true : false
	}

	Close() => this.Hide()

	; Everything the status strip shows, in one read: the log file is opened once
	; under the shared logging lock instead of once per value.
	; Processor use rides along because it is a rate: one sampler, read once per
	; poll, keeps the interval between samples steady for the strip and Health.
	GetSuiteStatusForWeb() {
		logState := ReadLogState()
		scripts := SuiteControl.ListRunningScripts(false)
		return JSON.Dump(Map(
			"profile", this.CurrentProfileName(),
			"uptimeSeconds", this.SessionUptimeSeconds(logState["sessionId"]),
			"entryCount", logState["entries"].Length,
			"runningScripts", scripts.Length,
			"cpu", this.SampleCpu(scripts),
			; Counting from a read cursor of zero counts every entry in the session.
			"logCounts", GetUnreadLogCounts(logState["entries"], 0),
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
		return TestRunStatus.Read(ControlDeck.TEST_STATUS_FILE, sessionStartedAt)
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

	; Pushing the section works once the page is up. On a cold start it is not:
	; the window title (the readiness signal a caller waits for) is published
	; before the page finishes loading, so the request is held until the page
	; asks for it. Without that, "open on Tests" from Run-Tests.ahk lands on
	; whatever the page opens by default.
	ShowSection(sectionName) {
		allowed := Map("overview", 1, "processes", 1, "logs", 1, "tests", 1, "profiles", 1, "health", 1)
		if !allowed.Has(sectionName)
			return
		if this._pageReady
			this.ExecuteScript("window.controlDeckShell && window.controlDeckShell.open(" JSON.Dump(sectionName) ")")
		else
			this._pendingSection := sectionName
	}

	; The page calls this once, as it starts: it both collects a section
	; requested before it existed and tells this side that pushes will land.
	TakePendingSection() {
		this._pageReady := true
		requestedSection := this._pendingSection
		this._pendingSection := ""
		return JSON.Dump(requestedSection)
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

	; Everything the Health section reports beyond processor use, which comes
	; with the suite status. The section asks once per visit, so the registry
	; and secrets lookups never run on the poll.
	GetHealthForWeb() {
		return JSON.Dump(Map(
			"autoHotkey", Map("version", A_AhkVersion, "path", A_AhkPath),
			"webView2", this.WebView2Runtime(),
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

	; Processor time is a rate, so it needs two samples. The first poll after
	; the page starts establishes the baseline and reports no percentage yet.
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
		for versionKey in ControlDeck.WEBVIEW2_VERSION_KEYS {
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
		if !FileExist(ControlDeck.SECRETS_FILE)
			return Map("status", "missing", "catalogKeys", catalogKeys, "keysWithValue", 0)
		try secrets := JSON.parse(FileRead(ControlDeck.SECRETS_FILE, "UTF-8"))
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
		testRunner := 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' ControlDeck.TEST_RUNNER_SCRIPT '"'
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
			"runs", TestRunStatus.ReadRuns(ControlDeck.TEST_HISTORY_FILE, sessionStartedAt)
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
		message := ControlDeck.TestMessages.Get(severity, "Test message")
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

	; --- Git ----------------------------------------------------------------

	; Read as the suite starts, on every Overview visit, and around each git
	; action. A checkout git cannot read reports no branch, which hides the
	; branch controls.
	GetGitStatusForWeb() {
		try return JSON.Dump(this.repository.Status())
		catch as gitError
			return JSON.Dump(Map("branch", "", "error", gitError.Message))
	}

	; No fetch here, so the menu opens at once; the page fetches separately and
	; asks again.
	GetGitBranchesForWeb() {
		try return JSON.Dump(this.repository.Branches())
		catch as gitError
			return JSON.Dump(Map("error", gitError.Message))
	}

	; mode is "" for a clean tree, or "stash" or "discard" as chosen in the page.
	SwitchGitBranch(branch, mode, stashMessage) {
		return this.ReportOutcome(() => this.repository.Switch(String(branch), String(mode), String(stashMessage)))
	}

	SyncGit() {
		try {
			synced := this.repository.Sync()
			synced["ok"] := 1
			return JSON.Dump(synced)
		} catch as gitError {
			return JSON.Dump(Map("ok", 0, "error", gitError.Message))
		}
	}
}
