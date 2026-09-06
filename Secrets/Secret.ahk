class Secret {
    __New(name, description, value := "", key := "") {
        this.name := name
        this.description := description
        this._value := value
        this.key := key
    }

    ; Retrieve the secret value (may be empty)
    Get() {
        SecretsFileManager.Initialize()
        if this._value = ""
            LogAndNotifyWarning("Secret not found: " . this.name)

        return this._value
    }

    ; Retrieve the secret value, if not set prompt the user to store it 
    GetOrSet() {
        SecretsFileManager.Initialize()
        if this._value != ""
            return this._value

        ; Prompt user for secret value, update file if provided
        this._value := SecretsUserInterface.AskForValue(this)
        if this._value != ""
            SecretsFileManager.UpdateExistingSecret(this)

        return this._value
    }

    ; Send() => ClipSend(this.GetOrSet()) sleep(100) Send("{BackSpace}") ; Remove space added by ClipSend
    Send() => ClipSend(this.GetOrSet())
}
