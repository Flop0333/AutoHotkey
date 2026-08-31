class SecretsFileManager {

    static FILE_PATH := Paths.autohotkey "\Secrets\My Secrets.json"
    static REMOVED_FILE_PATH := Paths.autohotkey "\Secrets\Removed Secrets.json"
    static CATALOG_FILE_PATH := Paths.autohotkey "\Secrets\Secrets Catalog.ahk"
    static MUTEX_NAME := "Local\AutoHotkey.SecretsFileManager"
    static MUTEX_TIMEOUT_MS := 10000
    static _initialized := false

    ; Load all values once, create the local file, and add newly required keys.
    static Initialize(force := false) {
        if this._initialized && !force
            return

        return this._WithFileLock(() => this._Initialize(force))
    }

    static _Initialize(force := false) {
        if this._initialized && !force
            return

        secrets := this._ReadSecrets()
        removedSecrets := this._ReadJsonFile(this.REMOVED_FILE_PATH)
        fileNeedsUpdate := !FileExist(this.FILE_PATH)
        removedFileNeedsUpdate := !FileExist(this.REMOVED_FILE_PATH)
        propertyNames := Map()
        displayNames := Map()

        for propertyName, secretDefinition in SecretsCatalog {
            propertyNames[propertyName] := true
            displayNames[secretDefinition.name] := true
            secretDefinition.key := propertyName

            if secrets.Has(propertyName) && Type(secrets[propertyName]) = "String" {
                secretDefinition._value := secrets[propertyName]
                if removedSecrets.Has(propertyName) {
                    removedSecrets.Delete(propertyName)
                    removedFileNeedsUpdate := true
                }
            } else if removedSecrets.Has(propertyName) && Type(removedSecrets[propertyName]) = "String" {
                ; Restore a preserved value when a removed catalog key is reintroduced.
                secretDefinition._value := removedSecrets[propertyName]
                secrets[propertyName] := secretDefinition._value
                removedSecrets.Delete(propertyName)
                fileNeedsUpdate := true
                removedFileNeedsUpdate := true
            } else if secrets.Has(secretDefinition.name) && Type(secrets[secretDefinition.name]) = "String" {
                ; Migrate files created by the earlier display-name-keyed format.
                secretDefinition._value := secrets[secretDefinition.name]
                secrets[propertyName] := secretDefinition._value
                fileNeedsUpdate := true
            } else {
                secretDefinition._value := ""
                secrets[propertyName] := ""
                fileNeedsUpdate := true
            }
        }

        ; Remove only obsolete keys known to belong to the previous format.
        for displayName in displayNames {
            if !propertyNames.Has(displayName) && secrets.Has(displayName) {
                secrets.Delete(displayName)
                fileNeedsUpdate := true
            }
        }

        ; Move secrets no longer defined by the catalog into the removal archive.
        removedKeys := []
        for secretKey in secrets
            if !propertyNames.Has(secretKey)
                removedKeys.Push(secretKey)

        for secretKey in removedKeys {
            removedSecrets[secretKey] := secrets[secretKey]
            secrets.Delete(secretKey)
            fileNeedsUpdate := true
            removedFileNeedsUpdate := true
        }

        if fileNeedsUpdate
            this._WriteSecrets(secrets)
        if removedFileNeedsUpdate
            this._WriteJsonFile(this.REMOVED_FILE_PATH, removedSecrets)

        this._initialized := true
    }

    static UpdateExistingSecret(secretToSave) => this._WithFileLock(() => this._SaveSecretValue(secretToSave))

    ; Store the value in JSON and add its non-secret definition to the catalog.
    static CreateNewSecret(secretToSave) => this._WithFileLock(() => this._CreateNewSecret(secretToSave))

    static _CreateNewSecret(secretToSave) {
        ; Persist the non-secret definition first. If saving the value then fails,
        ; the catalog remains valid and the value can safely be entered again.
        if !this._SaveSecretDefinition(secretToSave) || !this._SaveSecretValue(secretToSave)
            return false

        SecretsCatalog[secretToSave.key] := secretToSave
        return true
    }

    static _ReadSecrets() => this._ReadJsonFile(this.FILE_PATH)

    static _ReadJsonFile(filePath) {
        if !FileExist(filePath)
            return Map()

        jsonText := FileRead(filePath, "UTF-8")
        if !this._IsValidSecretsJson(jsonText)
            throw Error("Invalid secrets JSON. Expected one object containing only string keys and values. The original file was left untouched: " . filePath)

        try {
            values := JSON.parse(jsonText)
        } catch as parseError {
            throw Error("Invalid JSON. The original file was left untouched: " . filePath, -1, parseError.Message)
        }

        if Type(values) != "Map"
            throw Error("Expected a JSON object. The original file was left untouched: " . filePath)

        return values
    }

    static _IsValidSecretsJson(jsonText) {
        position := 1
        this._SkipJsonWhitespace(jsonText, &position)
        if SubStr(jsonText, position, 1) != "{"
            return false

        position += 1
        this._SkipJsonWhitespace(jsonText, &position)
        if SubStr(jsonText, position, 1) = "}" {
            position += 1
            this._SkipJsonWhitespace(jsonText, &position)
            return position > StrLen(jsonText)
        }

        loop {
            if !this._ConsumeJsonString(jsonText, &position)
                return false
            this._SkipJsonWhitespace(jsonText, &position)
            if SubStr(jsonText, position, 1) != ":"
                return false

            position += 1
            this._SkipJsonWhitespace(jsonText, &position)
            if !this._ConsumeJsonString(jsonText, &position)
                return false
            this._SkipJsonWhitespace(jsonText, &position)

            delimiter := SubStr(jsonText, position, 1)
            if delimiter = "}" {
                position += 1
                this._SkipJsonWhitespace(jsonText, &position)
                return position > StrLen(jsonText)
            }
            if delimiter != ","
                return false

            position += 1
            this._SkipJsonWhitespace(jsonText, &position)
        }
    }

    static _ConsumeJsonString(jsonText, &position) {
        quote := Chr(34)
        if SubStr(jsonText, position, 1) != quote
            return false

        position += 1
        while position <= StrLen(jsonText) {
            character := SubStr(jsonText, position, 1)
            if character = quote {
                position += 1
                return true
            }
            if Ord(character) < 0x20
                return false
            if character = "\" {
                position += 1
                escapeCode := SubStr(jsonText, position, 1)
                if InStr('"\/bfnrt', escapeCode) {
                    position += 1
                    continue
                }
                if escapeCode = "u" && RegExMatch(SubStr(jsonText, position + 1, 4), "i)^[0-9a-f]{4}$") {
                    position += 5
                    continue
                }
                return false
            }
            position += 1
        }
        return false
    }

    static _SkipJsonWhitespace(jsonText, &position) {
        while (character := SubStr(jsonText, position, 1)) != "" && InStr(" `t`r`n", character)
            position += 1
    }

    static _SaveSecretValue(secretToSave) {
        secretKey := this._GetSecretKey(secretToSave)
        if secretKey = "" {
            Info("Can't save secret without property name:`n`n" . secretToSave.name, 5000)
            return false
        }

        secrets := this._ReadSecrets()
        secrets[secretKey] := secretToSave._value
        this._WriteSecrets(secrets)
        Info("Saved secret to file`n`n" . secretToSave.name, 5000)
        return true
    }

    static _SaveSecretDefinition(secretToSave) {
        propertyName := this._GetSecretKey(secretToSave)
        if propertyName = "" {
            Info("Can't add secret without property name:`n`n" . secretToSave.name, 5000)
            return false
        }

        fileContent := FileRead(this.CATALOG_FILE_PATH)
        definition := "Secret(" . this._AhkStringLiteral(secretToSave.name) . ", " . this._AhkStringLiteral(secretToSave.description) . ")"
        newSecretEntry := ",`n    " . this._AhkStringLiteral(propertyName) . ", " . definition
        catalogClosePos := RegExMatch(fileContent, "m)^\h*\)\s*$")
        if catalogClosePos = 0
            throw Error("Could not find the SecretsCatalog closing parenthesis.")
        fileContent := SubStr(fileContent, 1, catalogClosePos - 1) . newSecretEntry . SubStr(fileContent, catalogClosePos)
        this._WriteFile(this.CATALOG_FILE_PATH, fileContent)
        return true
    }

    static _GetSecretKey(secret) {
        if secret.HasOwnProp("key") && secret.key != ""
            return secret.key
        
        ; If not provided, search the catalog.
        for propName, propValue in SecretsCatalog
            if (propValue == secret)
                return propName
        
        ; Return empty if property name cannot be determined
        ; This prevents creating malformed secret declarations in the file
        return ""
    }

    static _WriteFile(filePath, content) {
        tempPath := filePath . "." . DllCall("GetCurrentProcessId", "UInt") . "." . A_TickCount . ".tmp"
        try FileDelete(tempPath)
        try {
            FileAppend(content, tempPath, "UTF-8-RAW")
            FileMove(tempPath, filePath, true)
        } catch as writeError {
            try FileDelete(tempPath)
            throw writeError
        }
    }

    static _WriteSecrets(secrets) => this._WriteJsonFile(this.FILE_PATH, secrets)

    static _WriteJsonFile(filePath, values) => this._WriteFile(filePath, JSON.stringify(values, unset, "    "))

    static _AhkStringLiteral(value) {
        backtick := Chr(96)
        quote := Chr(34)
        escaped := StrReplace(value, backtick, backtick . backtick)
        escaped := StrReplace(escaped, "`r", backtick . "r")
        escaped := StrReplace(escaped, "`n", backtick . "n")
        escaped := StrReplace(escaped, "`t", backtick . "t")
        escaped := StrReplace(escaped, quote, backtick . quote)
        return quote . escaped . quote
    }

    static _WithFileLock(callback) {
        mutexHandle := DllCall("CreateMutex", "Ptr", 0, "Int", false, "Str", this.MUTEX_NAME, "Ptr")
        if !mutexHandle
            throw OSError()

        waitResult := DllCall("WaitForSingleObject", "Ptr", mutexHandle, "UInt", this.MUTEX_TIMEOUT_MS, "UInt")
        if waitResult != 0 && waitResult != 0x80 {
            DllCall("CloseHandle", "Ptr", mutexHandle)
            if waitResult = 0x102
                throw Error("Timed out waiting for access to the secrets files.")
            throw OSError()
        }

        try return callback.Call()
        finally {
            DllCall("ReleaseMutex", "Ptr", mutexHandle)
            DllCall("CloseHandle", "Ptr", mutexHandle)
        }
    }
}
