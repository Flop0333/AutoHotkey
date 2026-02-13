; ================================================================================
; === Fake Working Mode - Simulates activity to prevent system from going idle ===
; ================================================================================

#Include ..\Lib\Core.ahk

ToggleFakeWorkMode() => FakeWorkMode.Toggle()
GetFakeWorkModeState() => FakeWorkMode.Enabled


; Set default state for profile
if ProfileManager.Is(Profiles.devbox)
    FakeWorkMode.Toggle(true)


Class FakeWorkMode {
    static Enabled := false

    static Toggle(state := "") {
        this.Enabled := state = "" ? !this.Enabled : state
        if this.Enabled
            this.Start()
        Info("Fake Work Mode " (this.Enabled ? "Enabled" : "Disabled"))
    }
    
    static Start() {
        this.Enabled := true
        SetTimer(_TriggerAction, 60000) ; Perform action every min to keep system active

        _TriggerAction() {
            Send("{ScrollLock}")
            if this.Enabled = false
                SetTimer(_TriggerAction, 0)
        }
    }
}