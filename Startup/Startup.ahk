; ============================================================================
; === Startup - Initializes and runs all startup scripts =====================
; ============================================================================
;
; [SETUP]
;   1. Include a link to this file in your Startup folder or run it standalone
;   2. Secrets/My Secrets.json is created and synchronized automatically. The file
;       is not tracked; missing values safely resolve to an empty string.
; 
; [FEATURES]
;   - Manually set profile on startup (or auto-detect based on computer name)
;   - Switch profiles using tray menu
; ============================================================================
#Include ..\Dashboards\Logger\Logging.ahk
#Include ..\Dashboards\Test Dashboard\Test Dashboard.ahk
#Include ..\Lib\Core\Paths.ahk
#Include ..\Profiles\Profile Manager.ahk
#Include ..\Secrets\Secrets File Manager.ahk
#Include Startup Message.ahk
#Include Startup Menu Tray.ahk

RunStartup(profile?) {
    steps := [
        () => ClearErrorLog(),
        () => TraySetIcon(Paths.autoHotkeyIcon),
        () => StartupMessage(),
        () => StartupMenuTray(),
        () => SecretsFileManager.Initialize(),
        () => IsSet(profile) ? ProfileManager.Set(profile) : ProfileManager.SetByComputerName(),

        () => Run(Paths.appsStandalone "\Capslock Service.ahk"), ; Run this before scripts that set a capslock hotkey
        () => Run(Paths.dashboards "\Age of Efficiency\Age of Efficiency.ahk"),
        () => Run(Paths.dashboards "\Macro Board\Macro Board.ahk"),

        () => Run(Paths.appsStandalone "\Desktops Manager\Desktops Manager.ahk"),
        () => Run(Paths.appsStandalone "\Emoji Sender\Emoji Sender.ahk"),
        () => Run(Paths.appsStandalone "\Mouse Gestures\Mouse Gestures.ahk"),
        () => Run(Paths.appsStandalone "\Screen Snipper\Screen Snipper.ahk"),
        () => Run(Paths.appsStandalone "\Key Bindings.ahk"),
        () => Run(Paths.appsStandalone "\Text Speaker\Text Speaker.ahk"),
        () => Run(Paths.appsStandalone "\Window Manager.ahk"),

        () => Run(Paths.appsIntegrated "\Command Storer\Command Storer.ahk"),
        () => Run(Paths.appsIntegrated "\App Hotkeys.ahk"),
        () => Run(Paths.appsIntegrated "\Hotkeys.ahk"),
        () => Run(Paths.appsIntegrated "\Mouse Toys.ahk"),
    ]

    failuresCounter := 0
    for step in steps {
        try
            step()
        catch as startupError {
            failuresCounter++
            LogAndNotifyError("Startup step failed: " startupError.Message, startupError)
        }
    }

    InitializeLogging()
    
    if failuresCounter
        MsgBox failuresCounter " startup step(s) failed. See the error log for details.", "AutoHotkey Startup Error", 16
}

; Auto-run only when in Startup folder or run as standalone (not when #Include'd)
if (StrSplit(A_ScriptDir, "\").Pop() = StrSplit(A_Startup, "\").Pop())     
    RunStartup()


