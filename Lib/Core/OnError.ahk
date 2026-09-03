#Include ..\Tools\Info.ahk

OnError(HandleUnhandledError)

HandleUnhandledError(error, mode) {
    try Info("Unhandled error: " error.Message "`n" error.Stack, 4000)
    return true ; Suppress the default modal error dialog; the failed thread ends.
}
