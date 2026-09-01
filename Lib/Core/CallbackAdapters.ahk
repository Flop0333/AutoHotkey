; Callback adapters for safely invoking callbacks using SafeCall and ErrorReporter
#Include <Core\SafeCall>
#Include <Core\ErrorReporter>

Class CallbackAdapters {

    static MakeHotkeyHandler(operationId, callable, context := {}) {
            res := SafeCall(operationId, callable, context, [])
            if (res.status != "success")
                ErrorReporter.Notify("Operation '" operationId "' failed", (context.serviceId ?? operationId), "error")
    }

    static MakeTimerHandler(operationId, callable, context := {}) {
            res := SafeCall(operationId, callable, context, [])
            if (res.status != "success")
                ErrorReporter.Notify("Timer '" operationId "' failed", (context.serviceId ?? operationId), "error")
    }

    static MakeGuiEventHandler(operationId, callable, context := {}) {
            args := p*
            res := SafeCall(operationId, callable, context, args)
            if (res.status != "success")
                ErrorReporter.Notify("GUI event '" operationId "' failed", (context.serviceId ?? operationId), "error")

    }

    static MakeMenuHandler(operationId, callable, context := {}) {
            ; Menu callbacks usually don't receive args, but forward any provided
            res := SafeCall(operationId, callable, context, [])
            if (res.status != "success")
                ErrorReporter.Notify("Menu action '" operationId "' failed", (context.serviceId ?? operationId), "error")
    }
}
