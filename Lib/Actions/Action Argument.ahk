#Requires AutoHotkey v2

/**
 * Describes whether an action accepts input.
 *
 * Examples:
 *   ActionArgument.None()
 *   ActionArgument.Optional("Optional desktop setting")
 *   ActionArgument.Required("Timer length in minutes")
 */
class ActionArgument {
    static MODE_NONE := "none"
    static MODE_OPTIONAL := "optional"
    static MODE_REQUIRED := "required"

    __New(mode := "none", prompt := "") {
        mode := StrLower(mode)
        if mode != ActionArgument.MODE_NONE && mode != ActionArgument.MODE_OPTIONAL && mode != ActionArgument.MODE_REQUIRED
            throw ValueError("Invalid action argument mode: " mode)

        this._mode := mode
        this._prompt := prompt
    }

    Mode {
        get => this._mode
    }

    Prompt {
        get => this._prompt
    }

    AcceptsArgument {
        get => this._mode != ActionArgument.MODE_NONE
    }

    IsRequired {
        get => this._mode = ActionArgument.MODE_REQUIRED
    }

    static None() => ActionArgument(ActionArgument.MODE_NONE)
    static Optional(prompt := "") => ActionArgument(ActionArgument.MODE_OPTIONAL, prompt)
    static Required(prompt := "") => ActionArgument(ActionArgument.MODE_REQUIRED, prompt)
}
