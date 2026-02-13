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

class StartupMenuTray {
    __New() {
        A_TrayMenu.Delete()
        A_TrayMenu.Add("Reload", (*) => Reload())
        this._AddProfilesToTrayMenu()
        A_TrayMenu.Add("Exit", (*) => KillAllAHkProcesses())
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