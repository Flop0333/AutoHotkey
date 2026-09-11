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
#Include ..\Lib\Core\OnError.ahk
#Include ..\Dashboards\Logger\Logging.ahk
#Include ..\Lib\Core\Paths.ahk
#Include ..\Apps Integrated\Suite Control\Startup Scripts.ahk
#Include ..\Profiles\Profile Manager.ahk
#Include ..\Secrets\Secrets File Manager.ahk
#Include Startup Message.ahk
#Include Startup Menu Tray.ahk

RunStartup(profile?) {
    steps := [
        () => StartNewLogSession(),
        () => TraySetIcon(Paths.autoHotkeyIcon),
        () => StartupMessage(),
        () => StartupMenuTray(),
        () => SecretsFileManager.Initialize(),
        () => IsSet(profile) ? ProfileManager.Set(profile) : ProfileManager.SetForStartup(),

        () => InitializeLogging(),
    ]

    for scriptPath in SuiteStartupScripts()
        steps.InsertAt(7 + A_Index - 1, (path => () => Run(path))(scriptPath))

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

