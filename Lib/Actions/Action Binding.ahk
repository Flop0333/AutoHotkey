#Requires AutoHotkey v2
#Include Action Registry.ahk

/** Adapter used by hotkeys, gestures, and menus to invoke registered actions. */
class ActionBinding {
    static _failureHandler := (*) => ""

    static Callback(actionId, consumer := "binding") {
        this.Require(actionId)
        return (*) => this.Invoke(actionId, unset, consumer)
    }

    static Invoke(actionId, argument := unset, consumer := "binding") {
        context := ActionContext(consumer, "", WinExist("A"))
        result := IsSet(argument)
            ? ActionRegistry.Invoke(actionId, argument, context)
            : ActionRegistry.Invoke(actionId, unset, context)

        if result.status != ActionResult.STATUS_SUCCESS && result.status != ActionResult.STATUS_CANCELLED
            this._failureHandler.Call(result.message)
        return result
    }

    static BindHotkey(shortcut, actionId, consumer := "hotkey") {
        Hotkey(shortcut, this.Callback(actionId, consumer))
    }

    static Require(actionId) {
        if !ActionRegistry.Has(actionId)
            throw UnsetError("Binding references an unregistered action: " actionId)
        return actionId
    }

    static SetFailureHandler(handler) {
        if !HasMethod(handler, "Call")
            throw TypeError("ActionBinding failure handler must be callable")
        this._failureHandler := handler
    }
}
