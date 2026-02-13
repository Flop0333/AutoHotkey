; ============================================================================
; === Secrets Manager ========================================================
; ============================================================================
;
;   This class serves as the central repository for all application secrets (URLs, emails, API keys etc.)
;   The secrets are not tracked by git to prevent accidental sharing.
;
; [FEATURES]
;   On first access of a secret property, the user is prompted to enter the value.
;   The value is then saved to the local Secrets.ahk file for future use.
;
;   The SecretsFileManager class handles reading/writing the Secrets.ahk file.
;   If the Secrets.ahk file is missing, the SecretsBase class provides empty defaults.
;
; [SETUP]
;   1. Add a new property in the SecretsBase class
;      static NewSecret := Secret("Display Name", "Description", "")
;   2. Use it in code: SecretsBase.NewSecret.Get() to retrieve the value.
;      If you want the user to be prompted to set it if it's not set yet, use Secrets.NewSecret.GetOrSet() instead.
; ============================================================================

#Include Secrets.ahk
#Include ..\lib\Helpers\ClipSend.ahk

class Secret {
    __New(name, description, value := "", propName := "") {
        this.name := name
        this.description := description
        this._value := value
        this.propName := propName ; Used when creating a new secret
    }

    ; Retrieve the secret value (may be empty)
    Get() {
        if this._value = ""
            Info("Empty secret value: " . this.name, 3000)

        return this._value
    }

    ; Retrieve the secret value, if not set prompt the user to store it 
    GetOrSet() {
        if this._value != ""
            return this._value

        ; Prompt user for secret value, update file if provided
        this._value := SecretsUserInterface.AskForValue(this)
        if this._value != ""
            SecretsFileManager.UpdateExistingSecret(this)

        return this._value
    }

    Send() => ClipSend(this.GetOrSet()) sleep(100) Send("{BackSpace}") ; Remove space added by ClipSend
}

class SecretsFileManager {

    static FILE_PATH := Paths.autohotkey "\Secrets\Secrets.ahk"
    static BASE_FILE_PATH := Paths.autohotkey "\Secrets\Secrets Base.ahk"
    static FILE_EXAMPLE_PATH := Paths.autohotkey "\Secrets\Secrets Example.ahk"

    static GetSecretFromFile(requestedSecret) {
        fileContent := FileRead(this.FILE_PATH)
        needle := "Secret\(\s*`"" . requestedSecret.name . "`"\s*,\s*`"[^`"]*`"\s*,\s*`"(.*?)`""
        if (RegExMatch(fileContent, needle, &match))
            return match[1]
        return ""
    }

    ; Update an existing secret value in Secrets.ahk
    static UpdateExistingSecret(secretToSave) => this._SaveSecretToFile(secretToSave, this.FILE_PATH, true)

    ; Create a new secret in both Secrets.ahk and Secrets Base.ahk (without value) 
    static CreateNewSecret(secretToSave) {
        this._SaveSecretToFile(secretToSave, this.FILE_PATH, false)
        secretToSave._value := "" ; Clear value for base file
        return this._SaveSecretToFile(secretToSave, this.BASE_FILE_PATH, false)
    }

    static _SaveSecretToFile(secretToSave, filePath, updateOnly := false) {
        fileContent := FileRead(filePath)

        ; Regex matches constructor form with optional existing value
        needle := "Secret\(\s*`"" . secretToSave.name . "`"\s*,\s*`"([^`"]*)`"(?:\s*,\s*`"(.*?)`")?\s*\)"
        
        newValue := secretToSave._value
        backtickCharacter := Chr(96)
        doubleQuoteCharacter := Chr(34)
        
        ; Escape backticks by doubling them
        newValue := StrReplace(newValue, backtickCharacter, backtickCharacter . backtickCharacter)
        replacement := "Secret(" . doubleQuoteCharacter . secretToSave.name . doubleQuoteCharacter . ", " . doubleQuoteCharacter . secretToSave.description . doubleQuoteCharacter . ", " . doubleQuoteCharacter . newValue . doubleQuoteCharacter . ")"
        
        if RegExMatch(fileContent, needle, &match) {
            ; Secret found - update it
            fileContent := RegExReplace(fileContent, needle, replacement)
        } 
        else if !updateOnly {
            ; Secret not found - add it to the Secrets class
            lastBracePos := InStr(fileContent, "}", , -1)
            
            ; Get the property name to store it properly
            propertyName := this._GetPropertyName(secretToSave)
            if propertyName == "" {
                Info("Can't add secret without property name:`n`n" . secretToSave.name, 5000)
                return false ; Can't add secret without property name
            }

            ; Create the new secret line
            newSecretLine := "    static " . propertyName . " := " . replacement
            
            ; Insert the new secret before the closing brace
            fileContent := SubStr(fileContent, 1, lastBracePos - 1) . newSecretLine . "`n" . SubStr(fileContent, lastBracePos)
        } 
        else {
            Info("Secret not found in file and updateOnly is true:`n`n" . secretToSave.name, 5000)
            return false ; Can't update a secret that doesn't exist
        }
        
        ; Write to file safely
        this._WriteFile(filePath, fileContent)
        
        Info("Saved secret to file`n`n" . secretToSave.name . ": " . newValue, 5000)
        return true
    }

    static _GetPropertyName(secret) {
        ; First, check if propName was explicitly provided when creating the secret
        ; This is used when programmatically creating secrets
        if secret.HasOwnProp("propName") && secret.propName != ""
            return secret.propName
        
        ; If not provided, search through all Secrets class properties to find which one holds this secret
        ; This works when the secret was defined in the Secrets class and we're updating it
        for propName, propValue in Secrets.OwnProps()
            if (propValue == secret)
                return propName
        
        ; Return empty if property name cannot be determined
        ; This prevents creating malformed secret declarations in the file
        return ""
    }

    static _WriteFile(filePath, content) {
        tempPath := filePath . ".tmp"
        try FileDelete(tempPath)
        FileAppend(content, tempPath)
        try FileDelete(filePath)
        FileMove(tempPath, filePath)
    }
}

class SecretsUserInterface {

    static AskForValue(requestedSecret) {
        userInputSecretValue := InputBox("Secret: " requestedSecret.name "`nDescription: " . requestedSecret.description . "`n`nPlease provide a value`nCancel to leave empty.`n`nThis value will be saved to your local Secrets.ahk file (git-ignored).`nIt is stored unencrypted on your machine.", "Secret value not set! " . requestedSecret.name, "w500 h250")

        if userInputSecretValue.Result = "Ok"
            return userInputSecretValue.Value
        Info("Canceled input for secret:`n" . requestedSecret.name, 5000)
        return ""
    }
}