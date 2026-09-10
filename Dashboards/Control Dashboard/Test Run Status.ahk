; ============================================================================
; Test Run Status - Reads Logs\test-run-status.json for the dashboard
; ============================================================================
;
; [PURPOSE]
;   The test runners write one status file that outlives the suite. A result
;   from an earlier session is not this session's result, so reporting it
;   unchanged makes a dashboard opened right after startup claim the tests
;   passed - or failed - when nothing has run yet.
;
; [BEHAVIOR]
;   - A run still in progress is always reported as running.
;   - A finished run is reported only when it finished after the current log
;     session started, which is when the suite started.
;   - Anything older, missing, or unreadable reports "not run in this session".
; ============================================================================

#Include ..\..\Lib\Extensions\Json.ahk

class TestRunStatus {
	static NOT_RUN := "not-run"

	; statusFile is the runner's JSON status file; sessionStartedAt is an
	; AutoHotkey timestamp (yyyyMMddHHmmss) for the start of this suite session.
	static Read(statusFile, sessionStartedAt) {
		if !FileExist(statusFile)
			return Map("status", TestRunStatus.NOT_RUN)
		try status := JSON.parse(FileRead(statusFile, "UTF-8"))
		catch
			return Map("status", TestRunStatus.NOT_RUN)
		return TestRunStatus.ForSession(status, sessionStartedAt)
	}

	static ForSession(status, sessionStartedAt) {
		if !(status is Map)
			return Map("status", TestRunStatus.NOT_RUN)
		if (status.Get("status", "") = "running")
			return status

		finishedAt := TestRunStatus.ParseTimestamp(status.Get("lastRunAt", ""))
		if (finishedAt = "" || sessionStartedAt = "" || finishedAt < sessionStartedAt)
			return Map("status", TestRunStatus.NOT_RUN)
		return status
	}

	; "2026-09-10T09:58:00.1234567+02:00" becomes "20260910095800", which
	; compares directly against an AutoHotkey timestamp of the same length.
	static ParseTimestamp(value) {
		if !RegExMatch(String(value), "^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})", &parts)
			return ""
		return parts[1] parts[2] parts[3] parts[4] parts[5] parts[6]
	}
}
