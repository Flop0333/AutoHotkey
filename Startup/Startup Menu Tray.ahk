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

#Include ..\Lib\Helpers\System.ahk
class StartupMenuTray {
    __New() {
        ; Logging.ahk includes Core.ahk, whose #NoTrayIcon directive is correct
        ; for worker scripts but also applies to this combined startup script.
        ; Explicitly publish the startup owner's tray icon before building it.
        A_IconHidden := false
        A_TrayMenu.Delete()
        A_TrayMenu.Add("Reload", (*) => System.KillAndReload())
        this._AddProfilesToTrayMenu()
        A_TrayMenu.Add("Log Dashboard", (*) => ShowLogDashboard())
        A_TrayMenu.Add("Exit", (*) => System.KillAllAHkProcesses())
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
