#Requires AutoHotkey v2

/** Shared confirmation policy applied by ActionRegistry.Invoke(). */
class ActionConfirmation {
    static LEVEL_NORMAL := "normal"
    static LEVEL_SENSITIVE := "sensitive"
    static LEVEL_DESTRUCTIVE := "destructive"

    __New(level := "normal", message := "") {
        level := StrLower(level)
        if level != ActionConfirmation.LEVEL_NORMAL && level != ActionConfirmation.LEVEL_SENSITIVE && level != ActionConfirmation.LEVEL_DESTRUCTIVE
            throw ValueError("Invalid action confirmation level: " level)

        this._level := level
        this._message := message
    }

    Level {
        get => this._level
    }

    Message {
        get => this._message
    }

    IsRequired {
        get => this._level != ActionConfirmation.LEVEL_NORMAL
    }

    static Normal() => ActionConfirmation(ActionConfirmation.LEVEL_NORMAL)
    static Sensitive(message := "") => ActionConfirmation(ActionConfirmation.LEVEL_SENSITIVE, message)
    static Destructive(message := "") => ActionConfirmation(ActionConfirmation.LEVEL_DESTRUCTIVE, message)
}
