#Requires AutoHotkey v2
#Include ..\Support\Assert.ahk
#Include ..\..\Lib\Tools\Window Settings Service.ahk

TempWindowSettingsFile() {
    static counter := 0
    counter++
    directory := A_Temp "\ahk-window-settings-" A_TickCount "-" counter
    DirCreate(directory)
    return directory "\window settings.ini"
}

RemoveTempWindowSettingsFile(settingsFile) {
    SplitPath(settingsFile, , &directory)
    try DirDelete(directory, true)
}

WithTempWindowSettingsFile(testBody) {
    settingsFile := TempWindowSettingsFile()
    try testBody.Call(settingsFile)
    finally RemoveTempWindowSettingsFile(settingsFile)
}

Test_DefaultGeometry_IsCreatedForANewDashboard() {
    WithTempWindowSettingsFile((settingsFile) => (
        settings := WindowSettingsService(settingsFile, 1200, 800, 30, 40),
        Assert.Equal(1200, settings.Window.Width),
        Assert.Equal(800, settings.Window.Height),
        Assert.Equal(30, settings.Window.x),
        Assert.Equal(40, settings.Window.y),
        Assert.True(FileExist(settingsFile))
    ))
}

Test_SavedGeometry_SurvivesAServiceRestart() {
    WithTempWindowSettingsFile((settingsFile) => (
        settings := WindowSettingsService(settingsFile, 1200, 800, 30, 40),
        settings.Window.Width := 900,
        settings.Window.Height := 600,
        settings.Window.x := 75,
        settings.Window.y := 85,
        settings.SaveFile(),
        reloaded := WindowSettingsService(settingsFile, 1, 1, 1, 1),
        Assert.Equal(900, reloaded.Window.Width),
        Assert.Equal(600, reloaded.Window.Height),
        Assert.Equal(75, reloaded.Window.x),
        Assert.Equal(85, reloaded.Window.y)
    ))
}

TestKit.Run("New dashboards receive their configured default geometry", Test_DefaultGeometry_IsCreatedForANewDashboard)
TestKit.Run("Saved window geometry survives a settings-service restart", Test_SavedGeometry_SurvivesAServiceRestart)

TestKit.Report()
