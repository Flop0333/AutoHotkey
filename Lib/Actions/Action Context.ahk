#Requires AutoHotkey v2

/** Runtime information supplied by an action consumer. */
class ActionContext {
    __New(consumer := "unknown", profile := "", activeWindow := 0) {
        this.consumer := consumer
        this.profile := profile
        this.activeWindow := activeWindow
    }
}
