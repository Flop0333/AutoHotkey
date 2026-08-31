#Requires AutoHotkey v2

/**
 * Runtime information supplied by an action consumer.
 * profile is diagnostic context only; registry policy uses its trusted provider.
 */
class ActionContext {
    /** Captures who requested an action; profile cannot override registry policy. */
    __New(consumer := "unknown", profile := "", activeWindow := 0) {
        this.consumer := consumer
        this.profile := profile
        this.activeWindow := activeWindow
    }
}
