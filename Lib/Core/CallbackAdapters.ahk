#Requires AutoHotkey v2
#Include SafeCall.ahk
#Include Notifier.ahk

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
        safeContext := {}
        if IsSet(context) {
            if context is Map {
                for name, value in context
                    safeContext.%name% := value
            } else if IsObject(context) {
                for name, value in context.OwnProps()
                    safeContext.%name% := value
            }
        }
        safeContext.operationId := operationId
        result := SafeCall(callable, safeContext, args?)
        if result.status != "success" {
            serviceId := IsSet(context) && HasProp(context, "serviceId") ? context.serviceId : operationId
            Notifier.Error(kind " '" operationId "' failed", serviceId)
        }
        return result
    }
}
