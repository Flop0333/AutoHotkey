#Requires AutoHotkey v2

/**
 * Runtime information supplied by an action consumer.
 * profile is diagnostic context only; registry policy uses its trusted provider.
 */
class ActionContext {
    __New(consumer := "unknown", profile := "", activeWindow := 0) {
        this.consumer := consumer
        this.profile := profile
        this.activeWindow := activeWindow
    }
}
