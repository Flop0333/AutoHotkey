#Include ..\Tools\Info.ahk

OnError(HandleUnhandledError)

HandleUnhandledError(error, mode) {
    try Info("Unhandled error: " error.Message "`n" error.Stack)
    return true ; Suppress the default modal error dialog; the failed thread ends.
}
