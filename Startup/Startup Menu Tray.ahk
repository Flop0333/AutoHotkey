; ============================================================================
; === Startup Menu Tray - System tray interface for AHK suite =================
; ============================================================================
;
; [PURPOSE]
;   Creates the system tray menu with profile switching and reload capabilities.
;   Provides quick access to profile management without restarting manually.
;
; [FEATURES]
;   - Reload: Restarts current script (Startup.ahk)
;   - Profile menu: Switch between defined profiles (Work, Home, etc.)
;   - Exit: Terminates all running AHK processes
;
; [BEHAVIOR]
;   - Current profile is shown in menu and disabled from selection
;   - Switching profiles triggers full suite restart via RunStartup()
;   - All profile changes are persisted to current_profile.ini
; ============================================================================

#Include ..\Apps Integrated\Kill All Ahk Processes.ahk
#Include ..\Lib\Actions\Action Binding.ahk
#Include ..\Lib\Actions\Modules\System Actions.ahk

class StartupMenuTray {
    __New() {
		ActionRegistry.SetProfileProvider((*) => ProfileManager.current)
		ActionRegistry.RegisterIfMissing(SystemActions.ReloadStartup(RunStartup), "Startup Tray")
		ActionRegistry.RegisterIfMissing(SystemActions.KillAhkProcesses((*) => KillAllAHkProcesses(true)), "Startup Tray")
		ActionRegistry.RegisterIfMissing(SystemActions.RegistryDiagnostics((*) => MsgBox(ActionRegistry.FormatDiagnostics(), "Action Registry Diagnostics", "Iconi")), "Startup Tray")
        A_TrayMenu.Delete()
        A_TrayMenu.Add("Reload", ActionBinding.Callback(ActionIds.System.ReloadStartup, "startup-tray"))
        this._AddProfilesToTrayMenu()
        if ProfileManager.Is(Profiles.devbox)
            A_TrayMenu.Add("Action Registry Diagnostics", ActionBinding.Callback(ActionIds.System.RegistryDiagnostics, "startup-tray"))
        A_TrayMenu.Add("Exit", ActionBinding.Callback(ActionIds.System.KillAhkProcesses, "startup-tray"))
    }

    _AddProfilesToTrayMenu() {
        profileMenu := Menu()
        A_TrayMenu.Add("Profile (" ProfileManager.current.displayName ")", profileMenu)
        for profile in ProfileManager.allProfiles {
            profileMenu.Add(profile.displayName, (capturedProfile => (*) => RunStartup(capturedProfile))(profile))
            if (profile = ProfileManager.current)
                profileMenu.Disable(profile.displayName)
        }
    }
}
