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
    /** No input may be passed to the action. */
    static MODE_NONE := "none"
    /** Input may be passed, but omission is valid. */
    static MODE_OPTIONAL := "optional"
    /** Invoke() rejects the action when input is omitted. */
    static MODE_REQUIRED := "required"

    /** Creates and validates an argument policy. Prefer the factory methods below. */
    __New(mode := "none", prompt := "") {
        mode := StrLower(mode)
        if mode != ActionArgument.MODE_NONE && mode != ActionArgument.MODE_OPTIONAL && mode != ActionArgument.MODE_REQUIRED
            throw ValueError("Invalid action argument mode: " mode)

        this._mode := mode
        this._prompt := prompt
    }

    /** Normalized argument mode. */
    Mode {
        get => this._mode
    }

    /** Message a UI may show when asking for input. */
    Prompt {
        get => this._prompt
    }

    /** True for both optional and required arguments. */
    AcceptsArgument {
        get => this._mode != ActionArgument.MODE_NONE
    }

    /** True only when invocation must supply a non-empty argument. */
    IsRequired {
        get => this._mode = ActionArgument.MODE_REQUIRED
    }

    /** Creates a policy that rejects supplied input. */
    static None() => ActionArgument(ActionArgument.MODE_NONE)
    /** Creates a policy that accepts input but does not require it. */
    static Optional(prompt := "") => ActionArgument(ActionArgument.MODE_OPTIONAL, prompt)
    /** Creates a policy that requires input before execution. */
    static Required(prompt := "") => ActionArgument(ActionArgument.MODE_REQUIRED, prompt)
}
