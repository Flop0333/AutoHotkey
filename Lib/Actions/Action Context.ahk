#Requires AutoHotkey v2

/** Runtime information supplied by an action consumer. */
class ActionContext {
    __New(consumer := "unknown", profile := "", activeWindow := 0, confirmationGranted := false) {
        this.consumer := consumer
        this.profile := profile
        this.activeWindow := activeWindow
        this.confirmationGranted := confirmationGranted
    }
}
