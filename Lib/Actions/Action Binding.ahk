#Requires AutoHotkey v2
#Include Action Registry.ahk

/** Adapter used by hotkeys, gestures, and menus to invoke registered actions. */
class ActionBinding {
    static _failureHandler := (*) => ""

    /** Builds an AHK-compatible variadic callback and preserves the consumer name. */
    static Callback(actionId, consumer := "binding") {
        this.Require(actionId)
        return (*) => this.Invoke(actionId, unset, consumer)
    }

    /** Adds window context, invokes centrally, and reports non-cancellation failures. */
    static Invoke(actionId, argument := unset, consumer := "binding") {
        context := ActionContext(consumer, "", WinExist("A"))
        result := IsSet(argument)
            ? ActionRegistry.Invoke(actionId, argument, context)
            : ActionRegistry.Invoke(actionId, unset, context)

        if result.status != ActionResult.STATUS_SUCCESS && result.status != ActionResult.STATUS_CANCELLED
            this._failureHandler.Call(result.message)
        return result
    }

    /** Registers a normal AHK hotkey that routes through the registry. */
    static BindHotkey(shortcut, actionId, consumer := "hotkey") {
        Hotkey(shortcut, this.Callback(actionId, consumer))
    }

    /** Fails during setup rather than leaving a broken binding until first use. */
    static Require(actionId) {
        if !ActionRegistry.Has(actionId)
            throw UnsetError("Binding references an unregistered action: " actionId)
        return actionId
    }

    /** Injects presentation such as Info() without coupling the registry to a UI. */
    static SetFailureHandler(handler) {
        if !HasMethod(handler, "Call")
            throw TypeError("ActionBinding failure handler must be callable")
        this._failureHandler := handler
    }
}
