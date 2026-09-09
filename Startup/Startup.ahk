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
        { name: "Start new log session", action: () => StartNewLogSession() },
        { name: "Set startup tray icon", action: () => TraySetIcon(Paths.autoHotkeyIcon) },
        { name: "Show startup message", action: () => StartupMessage() },
        { name: "Configure startup tray menu", action: () => StartupMenuTray() },
        { name: "Initialize secrets", action: () => SecretsFileManager.Initialize() },
        { name: "Select active profile", action: () => IsSet(profile) ? ProfileManager.Set(profile) : ProfileManager.SetByComputerName() },

        ; Run this before scripts that set a CapsLock hotkey.
        { name: "Start Capslock Service", action: () => Run(Paths.appsStandalone "\Capslock Service.ahk") },
        { name: "Start Age of Efficiency", action: () => Run(Paths.dashboards "\Age of Efficiency\Age of Efficiency.ahk") },
        { name: "Start Macro Board", action: () => Run(Paths.dashboards "\Macro Board\Macro Board.ahk") },

        { name: "Start Desktops Manager", action: () => Run(Paths.appsStandalone "\Desktops Manager\Desktops Manager.ahk") },
        { name: "Start Emoji Sender", action: () => Run(Paths.appsStandalone "\Emoji Sender\Emoji Sender.ahk") },
        { name: "Start Mouse Gestures", action: () => Run(Paths.appsStandalone "\Mouse Gestures\Mouse Gestures.ahk") },
        { name: "Start Screen Snipper", action: () => Run(Paths.appsStandalone "\Screen Snipper\Screen Snipper.ahk") },
        { name: "Start Key Bindings", action: () => Run(Paths.appsStandalone "\Key Bindings.ahk") },
        { name: "Start Text Speaker", action: () => Run(Paths.appsStandalone "\Text Speaker\Text Speaker.ahk") },
        { name: "Start Window Manager", action: () => Run(Paths.appsStandalone "\Window Manager.ahk") },

        { name: "Start Command Storer", action: () => Run(Paths.appsIntegrated "\Command Storer\Command Storer.ahk") },
        { name: "Start App Hotkeys", action: () => Run(Paths.appsIntegrated "\App Hotkeys.ahk") },
        { name: "Start Hotkeys", action: () => Run(Paths.appsIntegrated "\Hotkeys.ahk") },
        { name: "Start Mouse Toys", action: () => Run(Paths.appsIntegrated "\Mouse Toys.ahk") },
        { name: "Initialize logger", action: () => InitializeLogging() },
    ]

    failures := []
    for step in steps {
        try
            step.action.Call()
        catch as startupError {
            failureMessage := step.name " failed: " startupError.Message
            failures.Push(failureMessage)

            ; Logging is best-effort here: a broken log path or lock must not
            ; abort the remaining startup steps or suppress the final dialog.
            try LogAndNotifyError(failureMessage,
                startupError.HasProp("Stack") ? startupError.Stack : "")
        }
    }

    if failures.Length {
        summary := failures.Length " startup step(s) failed:"
        for failure in failures
            summary .= "`n`n• " failure
        MsgBox summary, "AutoHotkey Startup Error", 16
    }
}

; Auto-run only when in Startup folder or run as standalone (not when #Include'd)
if (StrSplit(A_ScriptDir, "\").Pop() = StrSplit(A_Startup, "\").Pop())
    RunStartup()


