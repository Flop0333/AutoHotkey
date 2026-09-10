; ============================================================================
; === Profile Manager - Manages different profiles based on device names =====
; ============================================================================
;
; [SETUP]
;   1. Define profiles display names and device names
;      (device names can be retrieved using A_ComputerName)
;   2. Use ProfileManager.Is(Profiles.profileName) to check current profile
;      throughout your scripts and customize features accordingly
; 
; [FEATURES]
;   - Auto-detect profile based on A_ComputerName on startup
;   - Manually set profile if needed using tray menu (from startup.ahk) or function call
; ============================================================================

#Include ..\Lib\Core\Paths.ahk
#Include ..\Secrets\Secrets Service.ahk
#Include Profile Request.ahk

Class Profile {
    __New(displayName, deviceName) {
        this.displayName := displayName
        this.deviceName := deviceName is Array ? deviceName : [deviceName]
    }
}

Class Profiles {
    static work := Profile("Work", Secrets.WorkDeviceNames.Get())
    static devbox := Profile("Dev Box", ["DESKTOP-2NC1KCL", "CPC-fbrem-HLWU3"]) ; [VM, Dev Box]
    static woonkamerLaptops := Profile("Woonkamer Laptops", ["FLOPLAPTOP", "LAPTOP-LNTJIJKB"]) ; [Amyrion, Magneet]
    static default := Profile("Default", "")
}

Class ProfileManager {
    static current := Profiles.default
    static allProfiles := []
    static iniFile := Paths.profileIniFile
    
    static __New() {
        this._InitAllProfiles()
        this._LoadCurrentFromFile()
    }
    
    static Is(profiles*) {
        for profile in profiles
            if this.current = profile
                return true
        return false
    }

    ; Startup entry point: honor a profile requested before the restart, then
    ; fall back to auto-detection. Callers that already know the profile call
    ; Set() directly instead.
    static SetForStartup() {
        if requestedProfile := this._TakeRequestedProfile() {
            this.Set(requestedProfile)
            return
        }
        this.SetByComputerName()
    }

    ; Record the profile the next suite start should use. Combine with a suite
    ; reload to switch profiles from outside the Startup process.
    static RequestProfile(newProfile) {
        return ProfileRequest.Record(this.iniFile, newProfile.displayName)
    }

    static _TakeRequestedProfile() {
        requestedDisplayName := ProfileRequest.Take(this.iniFile)
        if (requestedDisplayName = "")
            return ""
        for profile in this.allProfiles
            if profile.displayName = requestedDisplayName
                return profile
        return "" ; A request for a profile that no longer exists is ignored.
    }

    static SetByComputerName() {
        for profile in this.allProfiles
            for device in profile.deviceName
                if (device && InStr(A_ComputerName, device)) {
                    this.current := profile
                    this._SaveCurrentProfileToFile()
                    return
            }

        this.Set(Profiles.default)
    }

    static Set(newProfile) {
        for profile in this.allProfiles {
            if profile = newProfile || profile.displayName = newProfile.displayName {
                this.current := profile
                this._SaveCurrentProfileToFile()
                ; An explicit choice supersedes anything still pending.
                ProfileRequest.Clear(this.iniFile)
                return
            }
        }
        MsgBox("Profile not found: " newProfile.displayName)
    }
    
    static _SaveCurrentProfileToFile() {
        try IniWrite(this.current.displayName, this.iniFile, "Profile", "Current")
        catch {
            Info("Writing ini file failed") ; Propably due to authorization issues on work device
        }
    }

    static _InitAllProfiles() {
        for propName in Profiles.OwnProps()
            if (Type(Profiles.%propName%) = "Profile")
                this.allProfiles.Push(Profiles.%propName%)
    }

    static _LoadCurrentFromFile() {
        try {
            savedProfileDisplayName := IniRead(this.iniFile, "Profile", "Current", "")
            for profile in this.allProfiles {
                if profile.displayName = savedProfileDisplayName {
                    this.current := profile
                    return
                }
            }
        } catch {
            MsgBox("Error reading profile ini file: " this.iniFile "`nSet profile by A_ComputerName")
            this.SetByComputerName()
        }
    }
}