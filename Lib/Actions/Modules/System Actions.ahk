#Requires AutoHotkey v2

/** Canonical definitions for system-level actions used by multiple consumers. */
class SystemActions {
    static CapsLockOff(execute) => Action("system.caps-lock.off", "Turn Caps Lock Off", execute, {
        description: "Ensure Caps Lock is turned off", category: "System"
    })

    static RegistryDiagnostics(execute) => Action("system.action-registry-diagnostics", "Action Registry Diagnostics", execute, {
        description: "Show safe registry validation information",
        category: "Development",
        icon: "Info",
        profiles: ["Dev Box"]
    })

    static ReloadStartup(execute) => Action("system.reload-startup", "Reload Startup", execute, {
        description: "Restart the configured AutoHotkey suite",
        category: "System",
        icon: "Restart"
    })

    static Shutdown(execute) => Action("system.shutdown", "Shut Down", execute, {
        description: "Shut down this computer",
        category: "System",
        icon: "Shut Down",
        confirmation: ActionConfirmation.Destructive("Shut down this computer?")
    })

    static KillAhkProcesses(execute) => Action("system.kill-ahk-processes", "Kill All AHK Processes", execute, {
        description: "Stop all AutoHotkey processes",
        category: "System",
        icon: "AutoHotkey",
        confirmation: ActionConfirmation.Destructive("Kill all AutoHotkey processes?")
    })
}
