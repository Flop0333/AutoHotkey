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

TestKit.Run("OpenInNewBrowser uses the injected run function", Test_OpenInNewBrowser_UsesInjectedRunFunction)
TestKit.Report()
