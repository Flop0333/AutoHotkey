#Requires AutoHotkey v2
#Include ..\Support\Assert.ahk
#Include ..\..\Profiles\Profile Manager.ahk
#Include ..\..\Apps Integrated\Suite Control\Startup Scripts.ahk

HasScript(scripts, scriptPath) {
    for candidate in scripts
        if (candidate = scriptPath)
            return true
    return false
}

notionBoard := Paths.dashboards "\Notion Board\Notion Board.ahk"
desktopsManager := Paths.appsStandalone "\Desktops Manager\Desktops Manager.ahk"

Test_WorkExcludesNotionBoardAndDesktopsManager() {
    scripts := SuiteStartupScripts(Profiles.work)
    Assert.Equal(14, scripts.Length)
    Assert.False(HasScript(scripts, notionBoard))
    Assert.False(HasScript(scripts, desktopsManager))
}

Test_DevboxExcludesOnlyNotionBoard() {
    scripts := SuiteStartupScripts(Profiles.devbox)
    Assert.Equal(15, scripts.Length)
    Assert.False(HasScript(scripts, notionBoard))
    Assert.True(HasScript(scripts, desktopsManager))
}

Test_WoonkamerLaptopsStartsEverything() {
    scripts := SuiteStartupScripts(Profiles.woonkamerLaptops)
    Assert.Equal(16, scripts.Length)
    Assert.True(HasScript(scripts, notionBoard))
    Assert.True(HasScript(scripts, desktopsManager))
}

Test_EstherStartsOnlyNotionBoard() {
    scripts := SuiteStartupScripts(Profiles.esther)
    Assert.ArrayEqual([notionBoard], scripts)
}

Test_DefaultExcludesOnlyNotionBoard() {
    scripts := SuiteStartupScripts(Profiles.default)
    Assert.Equal(15, scripts.Length)
    Assert.False(HasScript(scripts, notionBoard))
    Assert.True(HasScript(scripts, desktopsManager))
}

TestKit.Run("Work excludes Notion Board and Desktops Manager", Test_WorkExcludesNotionBoardAndDesktopsManager)
TestKit.Run("Dev Box excludes only Notion Board", Test_DevboxExcludesOnlyNotionBoard)
TestKit.Run("Woonkamer Laptops starts every application", Test_WoonkamerLaptopsStartsEverything)
TestKit.Run("Esthers Laptop starts only Notion Board", Test_EstherStartsOnlyNotionBoard)
TestKit.Run("Default excludes only Notion Board", Test_DefaultExcludesOnlyNotionBoard)
TestKit.Report()
