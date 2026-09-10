#Requires AutoHotkey v2
#Include ..\Support\Assert.ahk
#Include ..\..\Dashboards\Control Dashboard\Test Run Status.ahk

; The dashboard must never claim the tests passed - or failed - when the run it
; is reporting happened in an earlier suite session.

SESSION_START := "20260910080000"

Test_Timestamp_ReadsAnIsoRunTime() {
    Assert.Equal("20260910095800", TestRunStatus.ParseTimestamp("2026-09-10T09:58:00.1234567+02:00"))
    Assert.Equal("20260910095800", TestRunStatus.ParseTimestamp("2026-09-10T09:58:00"))
}

Test_Timestamp_RejectsAnythingElse() {
    Assert.Equal("", TestRunStatus.ParseTimestamp(""))
    Assert.Equal("", TestRunStatus.ParseTimestamp("yesterday"))
    Assert.Equal("", TestRunStatus.ParseTimestamp(0))
}

Test_ForSession_KeepsARunFromThisSession() {
    status := Map("status", "idle", "lastRunStatus", "FAIL", "lastRunAt", "2026-09-10T09:58:00+02:00")
    Assert.Equal("FAIL", TestRunStatus.ForSession(status, SESSION_START).Get("lastRunStatus", ""))
}

Test_ForSession_DropsARunFromAnEarlierSession() {
    status := Map("status", "idle", "lastRunStatus", "FAIL", "lastRunAt", "2026-09-09T21:14:00+02:00")
    reported := TestRunStatus.ForSession(status, SESSION_START)
    Assert.Equal(TestRunStatus.NOT_RUN, reported["status"])
    Assert.False(reported.Has("lastRunStatus"))
}

Test_ForSession_DropsAPassFromAnEarlierSessionToo() {
    status := Map("status", "idle", "lastRunStatus", "PASS", "lastRunAt", "2026-09-10T07:59:59+02:00")
    Assert.Equal(TestRunStatus.NOT_RUN, TestRunStatus.ForSession(status, SESSION_START)["status"])
}

Test_ForSession_AlwaysReportsARunInProgress() {
    status := Map("status", "running", "updatedAt", "2026-09-10T09:58:00+02:00")
    Assert.Equal("running", TestRunStatus.ForSession(status, SESSION_START)["status"])
}

Test_ForSession_ReportsNotRunWithoutASessionStart() {
    status := Map("status", "idle", "lastRunStatus", "PASS", "lastRunAt", "2026-09-10T09:58:00+02:00")
    Assert.Equal(TestRunStatus.NOT_RUN, TestRunStatus.ForSession(status, "")["status"])
}

Test_ForSession_ReportsNotRunForAnUnusableStatus() {
    Assert.Equal(TestRunStatus.NOT_RUN, TestRunStatus.ForSession(Map(), SESSION_START)["status"])
    Assert.Equal(TestRunStatus.NOT_RUN, TestRunStatus.ForSession("", SESSION_START)["status"])
    Assert.Equal(TestRunStatus.NOT_RUN, TestRunStatus.ForSession(Map("status", "idle"), SESSION_START)["status"])
}

Test_Read_ReportsNotRunWithoutAStatusFile() {
    missingFile := A_Temp "\ahk-test-run-status-missing-" A_TickCount ".json"
    Assert.Equal(TestRunStatus.NOT_RUN, TestRunStatus.Read(missingFile, SESSION_START)["status"])
}

Test_Read_ReportsNotRunForAnUnreadableStatusFile() {
    brokenFile := A_Temp "\ahk-test-run-status-broken-" A_TickCount ".json"
    FileAppend("{not json", brokenFile, "UTF-8")
    try Assert.Equal(TestRunStatus.NOT_RUN, TestRunStatus.Read(brokenFile, SESSION_START)["status"])
    finally FileDelete(brokenFile)
}

Test_Read_ReadsARunFromThisSession() {
    statusFile := A_Temp "\ahk-test-run-status-" A_TickCount ".json"
    FileAppend('{"status":"idle","lastRunStatus":"PASS","lastRunAt":"2026-09-10T09:58:00+02:00"}', statusFile, "UTF-8")
    try Assert.Equal("PASS", TestRunStatus.Read(statusFile, SESSION_START).Get("lastRunStatus", ""))
    finally FileDelete(statusFile)
}

TestKit.Run("An ISO run time becomes a comparable timestamp", Test_Timestamp_ReadsAnIsoRunTime)
TestKit.Run("Anything that is not an ISO run time yields no timestamp", Test_Timestamp_RejectsAnythingElse)
TestKit.Run("A run from this session is reported", Test_ForSession_KeepsARunFromThisSession)
TestKit.Run("A failure from an earlier session reports as not run", Test_ForSession_DropsARunFromAnEarlierSession)
TestKit.Run("A pass from an earlier session reports as not run", Test_ForSession_DropsAPassFromAnEarlierSessionToo)
TestKit.Run("A run in progress is always reported", Test_ForSession_AlwaysReportsARunInProgress)
TestKit.Run("Without a session start nothing is claimed to have run", Test_ForSession_ReportsNotRunWithoutASessionStart)
TestKit.Run("An unusable status reports as not run", Test_ForSession_ReportsNotRunForAnUnusableStatus)
TestKit.Run("A missing status file reports as not run", Test_Read_ReportsNotRunWithoutAStatusFile)
TestKit.Run("An unreadable status file reports as not run", Test_Read_ReportsNotRunForAnUnreadableStatusFile)
TestKit.Run("A status file from this session is read", Test_Read_ReadsARunFromThisSession)

TestKit.Report()
