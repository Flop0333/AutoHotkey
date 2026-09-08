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

Class Profile {
    __New(displayName, deviceName) {
        this.displayName := displayName
        this.deviceName := deviceName is Array ? deviceName : [deviceName]
    }
}

Class Profiles {
    ; Static field initializers run top-to-bottom the moment this class is
    ; defined (auto-execute, in every process that includes this file) - if
    ; Secrets.WorkDeviceNames.Get() ever throws, every field below "work"
    ; (including "default") never gets assigned, and anything reading
    ; Profiles.default (ProfileManager.current's own initializer) then fails
    ; too. Guard this one lookup so a broken secrets file can't take out the
    ; rest of the class.
    static work := Profile("Work", Profiles._SafeWorkDeviceNames())
    static devbox := Profile("Dev Box", ["DESKTOP-2NC1KCL", "CPC-fbrem-HLWU3"]) ; [VM, Dev Box]
    static woonkamerLaptops := Profile("Woonkamer Laptops", ["FLOPLAPTOP", "LAPTOP-LNTJIJKB"]) ; [Amyrion, Magneet]
    static default := Profile("Default", "")

    static _SafeWorkDeviceNames() {
        try return Secrets.WorkDeviceNames.Get()
        catch
            return ""
    }
}

Class ProfileManager {
    static current := Profiles.default
    static allProfiles := []
    static iniFile := Paths.profiles "\current_profile.ini"
    
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