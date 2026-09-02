#Include ..\Lib\Core\SafeCall.ahk

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
            Info("Empty secret value: " . this.name, 3000)

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

    ; Protect secret retrieval and transmission once, close to the risky operation.
    Send() => SafeCall((*) => ClipSend(this.GetOrSet()), "Could not send the secret"
    )
}
