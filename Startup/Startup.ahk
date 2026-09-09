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
#Include ..\Lib\Core\OnError.ahk
#Include ..\Dashboards\Test Dashboard\Test Dashboard.ahk
#Include ..\Lib\Core\Paths.ahk
#Include ..\Profiles\Profile Manager.ahk
#Include ..\Secrets\Secrets File Manager.ahk
#Include Startup Message.ahk
#Include Startup Menu Tray.ahk

InstallGlobalErrorHandler()

RunStartup(profile?) {
    steps := [
        () => StartNewLogSession(),
        () => TraySetIcon(Paths.autoHotkeyIcon),
        () => StartupMessage(),
        () => StartupMenuTray(),
        () => SecretsFileManager.Initialize(),
        () => IsSet(profile) ? ProfileManager.Set(profile) : ProfileManager.SetByComputerName(),

        ; Run this before scripts that set a CapsLock hotkey.
        () => Run(Paths.appsStandalone "\Capslock Service.ahk"),
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
        () => InitializeLogging(),
    ]

    failures := []
    for step in steps {
        try
            step.Call()
        catch as startupError {
            failureMessage := "Startup step failed: " startupError.Message
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

