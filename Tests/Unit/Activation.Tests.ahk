#Requires AutoHotkey v2
#Include ..\Support\Assert.ahk
#Include ..\..\Lib\Core\OnError.ahk
#Include ..\..\Apps Integrated\Fake Working Mode.ahk
#Include ..\..\Apps Integrated\Spell Checker.ahk

Test_GlobalErrorHandlerInstallation_IsIdempotent() {
    Assert.True(InstallGlobalErrorHandler())
    Assert.True(InstallGlobalErrorHandler())
}

Test_OptionalFeatures_AreInactiveUntilExplicitlyEnabled() {
    Assert.False(FakeWorkMode.Enabled)
    Assert.False(SpellChecker.Enabled)
    SpellChecker.Enable()
    Assert.True(SpellChecker.Enabled)
}

TestKit.Run("Global error-handler installation is idempotent", Test_GlobalErrorHandlerInstallation_IsIdempotent)
TestKit.Run("Optional features stay inactive until explicitly enabled", Test_OptionalFeatures_AreInactiveUntilExplicitlyEnabled)
TestKit.Report()
