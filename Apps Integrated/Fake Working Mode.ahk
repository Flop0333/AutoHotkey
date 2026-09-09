; ================================================================================
; === Fake Working Mode - Simulates activity to prevent system from going idle ===
; ================================================================================

#Include ..\Profiles\Profile Manager.ahk

InitializeFakeWorkModeForProfile() {
    if ProfileManager.Is(Profiles.devbox)
        FakeWorkMode.Start()
}


Class FakeWorkMode {
    static Enabled := false
    static _timerFunction := false

    static Toggle(state := "") {
        enabled := state = "" ? !this.Enabled : state
        enabled ? this.Start() : this.Stop()
        ; Info("Fake Work Mode " (this.Enabled ? "Enabled" : "Disabled"))
        return this.Enabled
    }
    
    static Start() {
        if this.Enabled
            return true
        this.Enabled := true
        this._timerFunction := (*) => Send("{ScrollLock}")
        SetTimer(this._timerFunction, 60000) ; Perform action every min to keep system active
        return true
    }

    static Stop() {
        if this._timerFunction
            SetTimer(this._timerFunction, 0)
        this.Enabled := false
        return false
    }
}
