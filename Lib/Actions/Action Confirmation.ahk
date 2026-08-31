#Requires AutoHotkey v2

/** Shared confirmation policy applied by ActionRegistry.Invoke(). */
class ActionConfirmation {
    /** Normal actions execute immediately. */
    static LEVEL_NORMAL := "normal"
    /** Sensitive actions require confirmation and are hidden from safe discovery. */
    static LEVEL_SENSITIVE := "sensitive"
    /** Destructive actions require confirmation and explicit discovery opt-in. */
    static LEVEL_DESTRUCTIVE := "destructive"

    /** Creates and validates a confirmation policy. Prefer the factory methods below. */
    __New(level := "normal", message := "") {
        level := StrLower(level)
        if level != ActionConfirmation.LEVEL_NORMAL && level != ActionConfirmation.LEVEL_SENSITIVE && level != ActionConfirmation.LEVEL_DESTRUCTIVE
            throw ValueError("Invalid action confirmation level: " level)

        this._level := level
        this._message := message
    }

    /** Normalized policy level. */
    Level {
        get => this._level
    }

    /** Optional custom question displayed before invocation. */
    Message {
        get => this._message
    }

    /** Normal actions are the only actions that do not prompt. */
    IsRequired {
        get => this._level != ActionConfirmation.LEVEL_NORMAL
    }

    /** Creates a no-prompt policy. */
    static Normal() => ActionConfirmation(ActionConfirmation.LEVEL_NORMAL)
    /** Creates a confirmation policy for secret or privacy-sensitive behavior. */
    static Sensitive(message := "") => ActionConfirmation(ActionConfirmation.LEVEL_SENSITIVE, message)
    /** Creates a confirmation policy for potentially damaging behavior. */
    static Destructive(message := "") => ActionConfirmation(ActionConfirmation.LEVEL_DESTRUCTIVE, message)
}
