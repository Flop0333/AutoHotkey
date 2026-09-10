; ============================================================================
; === Profile Request - One-shot profile handoff across a suite restart ======
; ============================================================================
;
; [PURPOSE]
;   A restart started outside the tray menu cannot pass a profile to the new
;   Startup process, and persisting the profile is not enough on its own:
;   RunStartup() without an argument auto-detects by computer name and
;   overwrites the stored choice. Recording a request here lets the next
;   startup honor "switch to this profile" exactly once.
;
; [BEHAVIOR]
;   - The request lives in the same git-ignored profile ini as the current
;     profile, under the same [Profile] section, so there is one local file.
;   - Take() is one-shot: the following startup auto-detects again.
;   - The ini path is passed in by the caller (ProfileManager owns it), which
;     also lets tests redirect the request to a temporary directory.
;   - Recording is best-effort: a device that refuses the write reports false
;     instead of throwing, matching how the current profile is persisted.
; ============================================================================

class ProfileRequest {
    static SECTION := "Profile"
    static KEY := "Requested"

    static Record(iniFile, displayName) {
        if (Trim(displayName) = "")
            return false
        try {
            IniWrite(displayName, iniFile, this.SECTION, this.KEY)
            return true
        }
        return false ; Probably due to authorization issues on work device
    }

    static Peek(iniFile) {
        try return Trim(IniRead(iniFile, this.SECTION, this.KEY, ""))
        return ""
    }

    static Take(iniFile) {
        requestedDisplayName := this.Peek(iniFile)
        this.Clear(iniFile)
        return requestedDisplayName
    }

    static Clear(iniFile) {
        try IniDelete(iniFile, this.SECTION, this.KEY)
    }
}
