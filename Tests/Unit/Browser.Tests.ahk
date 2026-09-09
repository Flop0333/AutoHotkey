#Requires AutoHotkey v2
#Include ..\Support\Assert.ahk
#Include ..\..\Lib\Apps\Browser.ahk

capturedBrowserRun := []

CaptureBrowserRun(arguments*) {
    global capturedBrowserRun := arguments
}

Test_OpenInNewBrowser_UsesInjectedRunFunction() {
    global capturedBrowserRun := []
    Browser.ConfigureRunFunction(CaptureBrowserRun)
    try {
        Browser.OpenInNewBrowser("https://example.test/path")
        Assert.True(capturedBrowserRun.Length >= 1)
        Assert.True(InStr(capturedBrowserRun[1], '--new-window "https://example.test/path"') > 0)
    } finally {
        Browser.ConfigureRunFunction()
    }
}

Test_DefaultBrowser_CanBeComposedExplicitly() {
    Browser.ConfigureDefaultBrowser(Edge)
    try Assert.Equal(Edge, Browser.defaultBrowser)
    finally Browser.ConfigureDefaultBrowser()
}

TestKit.Run("OpenInNewBrowser uses the injected run function", Test_OpenInNewBrowser_UsesInjectedRunFunction)
TestKit.Run("Default browser can be composed explicitly", Test_DefaultBrowser_CanBeComposedExplicitly)
TestKit.Report()
