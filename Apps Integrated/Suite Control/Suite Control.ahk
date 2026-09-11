; ============================================================================
; Suite Control - Suite-level lifecycle and process control
; ============================================================================
;
; [PURPOSE]
;   Owns the operations that act on the running AutoHotkey suite as a whole,
;   so the startup tray, a dashboard, a hotkey, and a test all drive the same
;   behavior. Lib\Helpers\System.ahk keeps the machine-level helpers
;   (shutdown, lock, sleep, display switching) and stays free of suite state.
;
; [FEATURES]
;   - Reload or exit the whole suite, with an injectable confirmation seam
;   - Inventory of the running AutoHotkey scripts (name, path, PID, start time)
;   - Restart one script, or stop one script, without touching the rest
;
; [USAGE]
;   SuiteControl.ReloadSuite()          ; asks first, then kills and restarts
;   SuiteControl.ReloadSuite(false)     ; no prompt
;   SuiteControl.ExitSuite(confirmFunc) ; confirmFunc.Call(message, title)
;   for script in SuiteControl.ListRunningScripts()
;       ...
;
;   Every call happens in the caller's own process. Reload and exit end that
;   process too, so a caller with its own UI should confirm before calling.
; ============================================================================

#Include ..\..\Lib\Core\Paths.ahk

; One running AutoHotkey script, as observed from outside its process.
class SuiteScript {
	__New(scriptPath, processId, windowHandle, startedAt) {
		SplitPath(scriptPath, &scriptName)
		this.name := scriptName
		this.path := scriptPath
		this.processId := processId
		this.windowHandle := windowHandle
		this.startedAt := startedAt ; "" when the start time could not be read
		this.belongsToSuite := (InStr(scriptPath, Paths.autohotkey) = 1)
	}

	UptimeSeconds => this.startedAt = "" ? "" : DateDiff(A_Now, this.startedAt, "Seconds")
}

class SuiteControl {

	; --- Suite lifecycle ----------------------------------------------------

	; Kills the rest of the suite, starts Startup.ahk again, and ends this
	; process. Returns false when the confirmation was declined; on success it
	; never returns, because the calling process exits.
	static ReloadSuite(confirm := true) {
		if !this._Confirmed(confirm, "Kill all AutoHotkey processes and reload?", "Kill and Reload")
			return false

		this._StopOtherAhkProcesses()
		Run(Paths.startup "\Startup.ahk")
		ExitApp
	}

	; Kills the rest of the suite and ends this process. Returns false when the
	; confirmation was declined.
	static ExitSuite(confirm := true) {
		if !this._Confirmed(confirm, "Kill all AutoHotkey processes?", "Kill AutoHotkey")
			return false

		this._StopOtherAhkProcesses()
		ExitApp
	}

	; --- Inventory ----------------------------------------------------------

	; Every running AutoHotkey script, newest window order aside, as SuiteScript
	; objects. GUI windows are skipped: only a script's main window carries the
	; "<path>.ahk - AutoHotkey v..." title this parses.
	; includeStartTime is opt-out because reading it queries WMI once per process:
	; a caller that only counts scripts should not pay for that every poll tick.
	static ListRunningScripts(includeStartTime := true) {
		scripts := []
		seenProcessIds := Map()
		previousDetectHiddenWindows := A_DetectHiddenWindows
		previousTitleMatchMode := A_TitleMatchMode
		DetectHiddenWindows(true)
		SetTitleMatchMode("RegEx") ; matches AutoHotkey.exe and AutoHotkey64.exe alike
		try {
			for windowHandle in WinGetList("ahk_exe AutoHotkey") {
				windowTitle := ""
				try windowTitle := WinGetTitle("ahk_id " windowHandle)
				scriptPath := this.ParseScriptPathFromWindowTitle(windowTitle)
				if (scriptPath = "")
					continue

				processId := 0
				try processId := WinGetPID("ahk_id " windowHandle)
				if (!processId || seenProcessIds.Has(processId))
					continue
				seenProcessIds[processId] := true

				startedAt := includeStartTime ? this.GetProcessStartTime(processId) : ""
				scripts.Push(SuiteScript(scriptPath, processId, windowHandle, startedAt))
			}
		} finally {
			SetTitleMatchMode(previousTitleMatchMode)
			DetectHiddenWindows(previousDetectHiddenWindows)
		}
		return scripts
	}

	; "C:\AutoHotkey\Apps Standalone\Window Manager.ahk - AutoHotkey v2.0.19"
	; becomes "C:\AutoHotkey\Apps Standalone\Window Manager.ahk". Anything else
	; - a GUI title, a compiled script, an unrelated window - becomes "".
	static ParseScriptPathFromWindowTitle(windowTitle) {
		if !(windowTitle is String)
			return ""
		return RegExMatch(windowTitle, "i)^(.+\.ahk) - AutoHotkey v\d", &titleMatch) ? titleMatch[1] : ""
	}

	; Pure comparison used by the dashboard and unit tests. Paths are compared
	; case-insensitively because Windows paths are case-insensitive.
	static FindMissingScripts(runningScripts, expectedPaths) {
		runningPaths := Map()
		for script in runningScripts
			runningPaths[StrLower(script.path)] := true
		missing := []
		for scriptPath in expectedPaths
			if !runningPaths.Has(StrLower(scriptPath))
				missing.Push(scriptPath)
		return missing
	}

	; Local process start time as an AutoHotkey timestamp, or "" when WMI is
	; unavailable or the process is already gone.
	static GetProcessStartTime(processId) {
		try {
			for process in ComObjGet("winmgmts:").ExecQuery("Select CreationDate from Win32_Process where ProcessId = " processId)
				return this.ParseWmiDateTime(process.CreationDate)
		}
		return ""
	}

	; WMI reports local time as "yyyymmddHHMMSS.ffffff+ZZZ"; AutoHotkey wants
	; the leading "yyyyMMddHHmmss" of that, which A_Now can be compared against.
	static ParseWmiDateTime(wmiDateTime) {
		return RegExMatch(String(wmiDateTime), "^(\d{14})", &dateTimeMatch) ? dateTimeMatch[1] : ""
	}

	; --- Processor usage ----------------------------------------------------

	; Total processor time consumed by every running AutoHotkey process, in
	; 100-nanosecond ticks. Only meaningful as a delta between two samples.
	; Processes this user cannot open (an elevated script) contribute nothing.
	static TotalCpuTicks(scripts?) {
		total := 0
		for script in (IsSet(scripts) ? scripts : this.ListRunningScripts(false))
			total += this.GetProcessCpuTicks(script.processId)
		return total
	}

	static GetProcessCpuTicks(processId) {
		static PROCESS_QUERY_LIMITED_INFORMATION := 0x1000
		processHandle := DllCall("OpenProcess", "UInt", PROCESS_QUERY_LIMITED_INFORMATION, "Int", false, "UInt", processId, "Ptr")
		if !processHandle
			return 0
		try {
			creationTime := Buffer(8, 0), exitTime := Buffer(8, 0), kernelTime := Buffer(8, 0), userTime := Buffer(8, 0)
			if !DllCall("GetProcessTimes", "Ptr", processHandle, "Ptr", creationTime, "Ptr", exitTime, "Ptr", kernelTime, "Ptr", userTime)
				return 0
			return NumGet(kernelTime, 0, "Int64") + NumGet(userTime, 0, "Int64")
		} finally {
			DllCall("CloseHandle", "Ptr", processHandle)
		}
	}

	; Share of the whole machine's processor capacity, the way Task Manager
	; reports it: one busy core on an eight-core machine is 12.5%, not 100%.
	; A tick is 100ns, so one core provides elapsedMs * 10000 ticks.
	; A negative delta means a process ended between samples; that reads as 0
	; rather than as a nonsensical negative percentage.
	static CpuPercentFromTicks(tickDelta, elapsedMs, processorCount) {
		if (tickDelta <= 0 || elapsedMs <= 0 || processorCount <= 0)
			return 0
		return Round(tickDelta / (elapsedMs * 10000 * processorCount) * 100, 1)
	}

	static ProcessorCount() {
		reported := EnvGet("NUMBER_OF_PROCESSORS")
		return IsInteger(reported) && Integer(reported) > 0 ? Integer(reported) : 1
	}

	; --- Single-script control ----------------------------------------------

	; Stops the process running scriptPath, if any, and starts the script again.
	; Other suite processes are left alone.
	static RestartScript(scriptPath) {
		if (Trim(scriptPath) = "")
			throw ValueError("A script path is required to restart a script", -1)

		for script in this.ListRunningScripts(false)
			if (script.path = scriptPath)
				this.StopScript(script.processId)

		Run('"' A_AhkPath '" "' scriptPath '"')
		return true
	}

	; Closes one script's main window and confirms the process is gone, falling
	; back to ProcessClose when it ignores the close. Refuses the caller's own
	; process: ending that is ExitApp's job, not a process kill.
	static StopScript(processId, timeoutSeconds := 3) {
		if (processId = this._CurrentProcessId())
			return false

		for script in this.ListRunningScripts(false) {
			if (script.processId != processId)
				continue
			previousDetectHiddenWindows := A_DetectHiddenWindows
			DetectHiddenWindows(true)
			try WinKill("ahk_id " script.windowHandle)
			DetectHiddenWindows(previousDetectHiddenWindows)
			break
		}

		if ProcessWaitClose(processId, timeoutSeconds)
			return true
		ProcessClose(processId)
		return !ProcessExist(processId)
	}

	; --- Internals ----------------------------------------------------------

	; confirm may be false (proceed silently), true (ask with a MsgBox), or a
	; callable seam that receives the message and title and returns truthy to
	; proceed. The callable check comes first: an object must not be compared
	; against a boolean.
	static _Confirmed(confirm, message, title) {
		if HasMethod(confirm)
			return !!confirm.Call(message, title)
		if !confirm
			return true
		return MsgBox(message, title, "YesNo") = "Yes"
	}

	; Kills every AutoHotkey window that belongs to another process. Windows of
	; the current process are skipped so a caller with its own GUI (a dashboard)
	; does not tear down the window it is being driven from before ExitApp.
	static _StopOtherAhkProcesses() {
		ownProcessId := this._CurrentProcessId()
		previousDetectHiddenWindows := A_DetectHiddenWindows
		previousTitleMatchMode := A_TitleMatchMode
		DetectHiddenWindows(true)
		SetTitleMatchMode("RegEx")
		try {
			for windowHandle in WinGetList("ahk_exe AutoHotkey") {
				try {
					if (WinGetPID("ahk_id " windowHandle) != ownProcessId)
						WinKill("ahk_id " windowHandle)
				}
			}
		} finally {
			SetTitleMatchMode(previousTitleMatchMode)
			DetectHiddenWindows(previousDetectHiddenWindows)
		}
	}

	static _CurrentProcessId() => DllCall("GetCurrentProcessId", "UInt")
}
