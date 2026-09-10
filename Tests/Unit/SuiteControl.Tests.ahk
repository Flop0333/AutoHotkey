#Requires AutoHotkey v2
#Include ..\Support\Assert.ahk
#Include ..\..\Apps Integrated\Suite Control\Suite Control.ahk

; Only the parsing helpers and the confirmation seam are exercised here.
; ReloadSuite/ExitSuite past a confirmed prompt, RestartScript, and StopScript
; kill real processes, so they are covered by hand and by the declined-prompt
; cases below - a unit test must never tear down the machine it runs on.

Test_ParseScriptPath_ReadsAPlainScriptTitle() {
    Assert.Equal("C:\AutoHotkey\Startup\Startup.ahk",
        SuiteControl.ParseScriptPathFromWindowTitle("C:\AutoHotkey\Startup\Startup.ahk - AutoHotkey v2.0.19"))
}

Test_ParseScriptPath_ReadsAPathContainingSpaces() {
    Assert.Equal("C:\My Repos\AutoHotkey\Apps Standalone\Window Manager.ahk",
        SuiteControl.ParseScriptPathFromWindowTitle("C:\My Repos\AutoHotkey\Apps Standalone\Window Manager.ahk - AutoHotkey v2.0.19"))
}

Test_ParseScriptPath_ReadsAnAlphaVersionTitle() {
    Assert.Equal("C:\AutoHotkey\Startup\Startup.ahk",
        SuiteControl.ParseScriptPathFromWindowTitle("C:\AutoHotkey\Startup\Startup.ahk - AutoHotkey v2.1-alpha.7"))
}

Test_ParseScriptPath_IgnoresAGuiWindowTitle() {
    Assert.Equal("", SuiteControl.ParseScriptPathFromWindowTitle("AutoHotkey Error Logger - Log Dashboard"))
}

Test_ParseScriptPath_IgnoresAnUnrelatedWindowTitle() {
    Assert.Equal("", SuiteControl.ParseScriptPathFromWindowTitle("Untitled - Notepad"))
}

Test_ParseScriptPath_IgnoresACompiledScriptTitle() {
    Assert.Equal("", SuiteControl.ParseScriptPathFromWindowTitle("C:\AutoHotkey\Startup\Startup.exe - AutoHotkey v2.0.19"))
}

Test_ParseScriptPath_IgnoresAnEmptyTitle() {
    Assert.Equal("", SuiteControl.ParseScriptPathFromWindowTitle(""))
}

Test_ParseScriptPath_IgnoresANonStringTitle() {
    Assert.Equal("", SuiteControl.ParseScriptPathFromWindowTitle(0))
}

TestKit.Run("Script path is read from a plain script window title", Test_ParseScriptPath_ReadsAPlainScriptTitle)
TestKit.Run("Script path keeps spaces in the path", Test_ParseScriptPath_ReadsAPathContainingSpaces)
TestKit.Run("Script path is read from an alpha-version title", Test_ParseScriptPath_ReadsAnAlphaVersionTitle)
TestKit.Run("A dashboard GUI title yields no script path", Test_ParseScriptPath_IgnoresAGuiWindowTitle)
TestKit.Run("An unrelated window title yields no script path", Test_ParseScriptPath_IgnoresAnUnrelatedWindowTitle)
TestKit.Run("A compiled script title yields no script path", Test_ParseScriptPath_IgnoresACompiledScriptTitle)
TestKit.Run("An empty title yields no script path", Test_ParseScriptPath_IgnoresAnEmptyTitle)
TestKit.Run("A non-string title yields no script path", Test_ParseScriptPath_IgnoresANonStringTitle)

Test_ParseWmiDateTime_KeepsTheTimestampPrefix() {
    Assert.Equal("20260910193015", SuiteControl.ParseWmiDateTime("20260910193015.123456+120"))
}

Test_ParseWmiDateTime_AcceptsATimestampWithoutAFraction() {
    Assert.Equal("20260910193015", SuiteControl.ParseWmiDateTime("20260910193015"))
}

Test_ParseWmiDateTime_RejectsAnUnexpectedValue() {
    Assert.Equal("", SuiteControl.ParseWmiDateTime("not-a-timestamp"))
    Assert.Equal("", SuiteControl.ParseWmiDateTime(""))
}

TestKit.Run("WMI creation date keeps its timestamp prefix", Test_ParseWmiDateTime_KeepsTheTimestampPrefix)
TestKit.Run("WMI creation date without a fraction is accepted", Test_ParseWmiDateTime_AcceptsATimestampWithoutAFraction)
TestKit.Run("An unexpected WMI creation date yields no timestamp", Test_ParseWmiDateTime_RejectsAnUnexpectedValue)

Test_Confirmed_SkipsThePromptWhenConfirmIsFalse() {
    Assert.True(SuiteControl._Confirmed(false, "message", "title"))
}

Test_Confirmed_UsesTheInjectedSeam() {
    receivedMessage := "", receivedTitle := ""
    accept := (message, title) => (receivedMessage := message, receivedTitle := title, true)
    Assert.True(SuiteControl._Confirmed(accept, "Reload?", "Reload"))
    Assert.Equal("Reload?", receivedMessage)
    Assert.Equal("Reload", receivedTitle)
}

Test_Confirmed_HonorsADecliningSeam() {
    Assert.False(SuiteControl._Confirmed((*) => false, "message", "title"))
}

TestKit.Run("A false confirmation proceeds without prompting", Test_Confirmed_SkipsThePromptWhenConfirmIsFalse)
TestKit.Run("An injected confirmation seam receives the message and title", Test_Confirmed_UsesTheInjectedSeam)
TestKit.Run("A declining confirmation seam stops the operation", Test_Confirmed_HonorsADecliningSeam)

; The important half of the seam: declining must not touch a single process.
Test_ReloadSuite_DoesNothingWhenDeclined() {
    Assert.False(SuiteControl.ReloadSuite((*) => false))
}

Test_ExitSuite_DoesNothingWhenDeclined() {
    Assert.False(SuiteControl.ExitSuite((*) => false))
}

Test_StopScript_RefusesTheCurrentProcess() {
    Assert.False(SuiteControl.StopScript(DllCall("GetCurrentProcessId", "UInt")))
}

Test_RestartScript_RequiresAScriptPath() {
    Assert.Throws(() => SuiteControl.RestartScript(""))
    Assert.Throws(() => SuiteControl.RestartScript("   "))
}

TestKit.Run("A declined reload leaves the suite running", Test_ReloadSuite_DoesNothingWhenDeclined)
TestKit.Run("A declined exit leaves the suite running", Test_ExitSuite_DoesNothingWhenDeclined)
TestKit.Run("Stopping the current process is refused", Test_StopScript_RefusesTheCurrentProcess)
TestKit.Run("Restarting without a script path throws", Test_RestartScript_RequiresAScriptPath)

Test_SuiteScript_DescribesTheScript() {
    script := SuiteScript(Paths.autohotkey "\Startup\Startup.ahk", 1234, 0x1000, "")
    Assert.Equal("Startup.ahk", script.name)
    Assert.Equal(1234, script.processId)
    Assert.Equal(0x1000, script.windowHandle)
    Assert.Equal("", script.startedAt)
    Assert.Equal("", script.UptimeSeconds)
    Assert.True(script.belongsToSuite)
}

Test_SuiteScript_MarksAScriptOutsideTheRepository() {
    Assert.False(SuiteScript("C:\Elsewhere\Stray.ahk", 1234, 0x1000, "").belongsToSuite)
}

Test_SuiteScript_ReportsUptimeFromTheStartTime() {
    startedAt := DateAdd(A_Now, -90, "Seconds")
    Assert.True(SuiteScript("C:\Elsewhere\Stray.ahk", 1234, 0x1000, startedAt).UptimeSeconds >= 90)
}

TestKit.Run("A suite script exposes its name, ids, and empty uptime", Test_SuiteScript_DescribesTheScript)
TestKit.Run("A script outside the repository is not part of the suite", Test_SuiteScript_MarksAScriptOutsideTheRepository)
TestKit.Run("A suite script reports uptime from its start time", Test_SuiteScript_ReportsUptimeFromTheStartTime)

TestKit.Report()
