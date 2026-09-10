#Requires AutoHotkey v2
#Include ..\Support\Assert.ahk
#Include ..\..\Profiles\Profile Request.ahk

; The real Profiles\current_profile.ini is personal, machine-specific state, so
; every case here works on its own ini file in a temporary directory.

TempIniFile() {
    static counter := 0
    counter++
    directory := A_Temp "\ahk-profile-request-" A_TickCount "-" counter
    DirCreate(directory)
    return directory "\current_profile.ini"
}

RemoveTempIniFile(iniFile) {
    SplitPath(iniFile, , &directory)
    try DirDelete(directory, true)
}

WithTempIniFile(testBody) {
    iniFile := TempIniFile()
    try testBody.Call(iniFile)
    finally RemoveTempIniFile(iniFile)
}

Test_Peek_ReturnsNothingWithoutAFile() {
    WithTempIniFile((iniFile) => Assert.Equal("", ProfileRequest.Peek(iniFile)))
}

Test_Record_StoresTheRequestedProfile() {
    WithTempIniFile((iniFile) => (
        Assert.True(ProfileRequest.Record(iniFile, "Work")),
        Assert.Equal("Work", ProfileRequest.Peek(iniFile))
    ))
}

Test_Record_KeepsOnlyTheLatestRequest() {
    WithTempIniFile((iniFile) => (
        ProfileRequest.Record(iniFile, "Work"),
        ProfileRequest.Record(iniFile, "Dev Box"),
        Assert.Equal("Dev Box", ProfileRequest.Peek(iniFile))
    ))
}

Test_Record_RejectsAnEmptyDisplayName() {
    WithTempIniFile((iniFile) => (
        Assert.False(ProfileRequest.Record(iniFile, "")),
        Assert.False(ProfileRequest.Record(iniFile, "   ")),
        Assert.Equal("", ProfileRequest.Peek(iniFile))
    ))
}

Test_Record_ReportsFailureInsteadOfThrowing() {
    unwritableIniFile := A_Temp "\ahk-profile-request-missing-" A_TickCount "\nested\current_profile.ini"
    Assert.False(ProfileRequest.Record(unwritableIniFile, "Work"))
}

Test_Take_HonorsTheRequestExactlyOnce() {
    WithTempIniFile((iniFile) => (
        ProfileRequest.Record(iniFile, "Work"),
        Assert.Equal("Work", ProfileRequest.Take(iniFile)),
        Assert.Equal("", ProfileRequest.Peek(iniFile)),
        Assert.Equal("", ProfileRequest.Take(iniFile))
    ))
}

Test_Take_ReturnsNothingWithoutARequest() {
    WithTempIniFile((iniFile) => Assert.Equal("", ProfileRequest.Take(iniFile)))
}

Test_Clear_RemovesAPendingRequest() {
    WithTempIniFile((iniFile) => (
        ProfileRequest.Record(iniFile, "Work"),
        ProfileRequest.Clear(iniFile),
        Assert.Equal("", ProfileRequest.Peek(iniFile))
    ))
}

Test_Clear_IsSafeWithoutAFile() {
    WithTempIniFile((iniFile) => Assert.DoesNotThrow(() => ProfileRequest.Clear(iniFile)))
}

Test_Request_LeavesTheCurrentProfileAlone() {
    WithTempIniFile((iniFile) => (
        IniWrite("Work", iniFile, "Profile", "Current"),
        ProfileRequest.Record(iniFile, "Dev Box"),
        ProfileRequest.Take(iniFile),
        Assert.Equal("Work", IniRead(iniFile, "Profile", "Current", ""))
    ))
}

TestKit.Run("Peeking without a file reports no request", Test_Peek_ReturnsNothingWithoutAFile)
TestKit.Run("Recording stores the requested profile", Test_Record_StoresTheRequestedProfile)
TestKit.Run("Recording twice keeps only the latest request", Test_Record_KeepsOnlyTheLatestRequest)
TestKit.Run("An empty display name is not recorded", Test_Record_RejectsAnEmptyDisplayName)
TestKit.Run("An unwritable location reports failure instead of throwing", Test_Record_ReportsFailureInsteadOfThrowing)
TestKit.Run("A request is honored exactly once", Test_Take_HonorsTheRequestExactlyOnce)
TestKit.Run("Taking without a request reports nothing", Test_Take_ReturnsNothingWithoutARequest)
TestKit.Run("Clearing removes a pending request", Test_Clear_RemovesAPendingRequest)
TestKit.Run("Clearing without a file is safe", Test_Clear_IsSafeWithoutAFile)
TestKit.Run("A request never disturbs the stored current profile", Test_Request_LeavesTheCurrentProfileAlone)

TestKit.Report()
