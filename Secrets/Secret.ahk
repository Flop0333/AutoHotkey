class Secret {
    __New(name, description, value := "", key := "") {
        this.name := name
        this.description := description
        this._value := value
        this.key := key
    }

    ; Retrieve the secret value (may be empty)
    Get() {
        if !this._TryInitialize()
            return ""
        if this._value = ""
            LogAndNotifyWarning("Secret not found: " . this.name)

        return this._value
    }

    ; Retrieve the secret value, if not set prompt the user to store it
    GetOrSet() {
        if !this._TryInitialize()
            return ""
        if this._value != ""
            return this._value

        ; Prompt user for secret value, update file if provided
        this._value := SecretsUserInterface.AskForValue(this)
        if this._value != ""
            SecretsFileManager.UpdateExistingSecret(this)

        return this._value
    }

    ; Every secret access routes through SecretsFileManager.Initialize(), which
    ; throws when the secrets file is broken (e.g. invalid JSON). Left
    ; uncaught, that exception surfaces from whatever script happened to touch
    ; a secret first - usually far away from Startup.ahk, in a process whose
    ; own OnError handler only logs quietly. Surface it here instead, once per
    ; secret access, so the caller sees a clear reason the value came back empty.
    _TryInitialize() {
        try {
            SecretsFileManager.Initialize()
            return true
        } catch as initError {
            ; Never let reporting the failure become a second failure - Get()/
            ; GetOrSet() must always return a value, not throw.
            try LogAndNotifyError("Secret '" . this.name . "' unavailable - the secrets file failed to load: " . initError.Message,
                initError.HasProp("Stack") ? initError.Stack : "")
            return false
        }
    }

    ; Send() => ClipSend(this.GetOrSet()) sleep(100) Send("{BackSpace}") ; Remove space added by ClipSend
    Send() => ClipSend(this.GetOrSet())
}
