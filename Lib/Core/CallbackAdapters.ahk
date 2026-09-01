#Requires AutoHotkey v2
#Include SafeCall.ahk

/** Produces callbacks which preserve the arguments supplied by AutoHotkey. */
class CallbackAdapters {
    static MakeHotkeyHandler(operationId, callable, context := unset) {
        return (callbackArgs*) => this._Invoke("Operation", operationId, callable, context?, callbackArgs)
    }

    static MakeTimerHandler(operationId, callable, context := unset) {
        return (callbackArgs*) => this._Invoke("Timer", operationId, callable, context?, callbackArgs)
    }

    static MakeGuiEventHandler(operationId, callable, context := unset) {
        return (callbackArgs*) => this._Invoke("GUI event", operationId, callable, context?, callbackArgs)
    }

    static MakeMenuHandler(operationId, callable, context := unset) {
        return (callbackArgs*) => this._Invoke("Menu action", operationId, callable, context?, callbackArgs)
    }

    static _Invoke(kind, operationId, callable, context := unset, args := unset) {
        result := SafeCall(operationId, callable, context?, args?)
        if result.status != "success" {
            serviceId := IsSet(context) && HasProp(context, "serviceId") ? context.serviceId : operationId
            ErrorReporter.Notify(kind " '" operationId "' failed", serviceId, "error")
        }
        return result
    }
}
