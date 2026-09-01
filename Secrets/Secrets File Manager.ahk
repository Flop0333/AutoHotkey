class SecretsFileManager {

    static FILE_PATH := Paths.autohotkey "\Secrets\My Secrets.json"
    static REMOVED_FILE_PATH := Paths.autohotkey "\Secrets\Removed Secrets.json"
    static CATALOG_FILE_PATH := Paths.autohotkey "\Secrets\Secrets Catalog.ahk"
    ; Local\ scopes the shared lock to the current Windows login session.
    static MUTEX_NAME := "Local\AutoHotkey.SecretsFileManager"
    static MUTEX_TIMEOUT_MS := 10000
    static _initialized := false

    ; Load all values once, create the local file, and add newly required keys.
    static Initialize(force := false) {
        if this._initialized && !force
            return

        ; Synchronization is a read-modify-write operation shared by all AHK processes.
        return this._WithFileLock(() => this._Initialize(force))
    }

    ; Synchronize in-memory secrets, active values, removed values, and catalog definitions.
    static _Initialize(force := false) {
        if this._initialized && !force
            return

        ; Read both files before changing anything, so a parse error cannot cause a partial sync.
        secrets := this._ReadSecrets()
        removedSecrets := this._ReadJsonFile(this.REMOVED_FILE_PATH)
        fileNeedsUpdate := !FileExist(this.FILE_PATH)
        removedFileNeedsUpdate := !FileExist(this.REMOVED_FILE_PATH)
        propertyNames := Map()
        displayNames := Map()

        for propertyName, secretDefinition in SecretsCatalog {
            ; The catalog key is the stable identifier used in both JSON files.
            propertyNames[propertyName] := true
            displayNames[secretDefinition.name] := true
            secretDefinition.key := propertyName

            if secrets.Has(propertyName) && Type(secrets[propertyName]) = "String" {
                secretDefinition._value := secrets[propertyName]
                ; An active catalog entry must not also remain in the archive.
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
                ; New catalog entries start empty on machines that have just pulled them.
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

        ; Avoid unnecessary disk writes when both files already match the catalog.
        if fileNeedsUpdate
            this._WriteSecrets(secrets)
        if removedFileNeedsUpdate
            this._WriteJsonFile(this.REMOVED_FILE_PATH, removedSecrets)

        this._initialized := true
    }

    ; Lock the complete read-modify-write cycle so concurrent updates cannot overwrite each other.
    static UpdateExistingSecret(secretToSave) {
        return this._WithFileLock(() => this._SaveSecretValue(secretToSave))
    }

    ; Persist a new secret value and add its non-secret definition to the catalog.
    static CreateNewSecret(secretToSave) => this._WithFileLock(() => this._CreateNewSecret(secretToSave))

    ; Perform new-secret persistence while the caller holds the shared file lock.
    static _CreateNewSecret(secretToSave) {
        ; Persist the non-secret definition first. If saving the value then fails,
        ; the catalog remains valid and the value can safely be entered again.
        if !this._SaveSecretDefinition(secretToSave) || !this._SaveSecretValue(secretToSave)
            return false

        SecretsCatalog[secretToSave.key] := secretToSave
        return true
    }

    ; Read the active local secrets file.
    static _ReadSecrets() => this._ReadJsonFile(this.FILE_PATH)
    

    ; Read and validate a secrets JSON file, returning an empty map when it does not exist.
    static _ReadJsonFile(filePath) {
        if !FileExist(filePath)
            return Map()

        ; Validate the narrow secrets-file format before using the permissive JSON helper.
        jsonText := FileRead(filePath, "UTF-8")
        validationResult := this._IsValidSecretsJson(jsonText)
        if validationResult !== true {
            message := "Invalid secrets JSON "
            if Type(validationResult) = "String"
                message .= validationResult
            throw Error(message . ". Expected one object containing only string keys and values. The original file was left untouched: " . filePath)
        }

        try {
            values := JSON.parse(jsonText)
        } catch as parseError {
            throw Error("Invalid JSON. The original file was left untouched: " . filePath, -1, parseError.Message)
        }

        if Type(values) != "Map"
            throw Error("Expected a JSON object. The original file was left untouched: " . filePath)

        return values
    }

    ; Check that JSON follows the supported string-key/string-value object format.
    static _IsValidSecretsJson(jsonText) {
        ; Small bounded parser: only { "key": "value" } pairs are allowed here.
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
            key := this._ConsumeJsonString(jsonText, &position)
            if key = false
                return false
            this._SkipJsonWhitespace(jsonText, &position)
            if SubStr(jsonText, position, 1) != ":"
                return false

            position += 1
            this._SkipJsonWhitespace(jsonText, &position)
            value := this._ConsumeJsonString(jsonText, &position)
            if value = false
                return "for property: " . key . " (expected string only)"
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

    ; Validate one JSON string token and advance the parser position past it.
    static _ConsumeJsonString(jsonText, &position) {
        ; Walk escapes explicitly so malformed or unterminated strings are rejected.
        quote := Chr(34)
        if SubStr(jsonText, position, 1) != quote
            return false

        position += 1
        result := ""
        while position <= StrLen(jsonText) {
            character := SubStr(jsonText, position, 1)
            if character = quote {
                position += 1
                return result
            }
            if Ord(character) < 0x20
                return false
            if character = "\" {
                position += 1
                escapeCode := SubStr(jsonText, position, 1)
                if InStr('"\\/bfnrt', escapeCode) {
                    ; Map common escapes
                    mapped := escapeCode
                    if escapeCode = 'b'
                        mapped := Chr(8)
                    else if escapeCode = 'f'
                        mapped := Chr(12)
                    else if escapeCode = 'n'
                        mapped := "`n"
                    else if escapeCode = 'r'
                        mapped := "`r"
                    else if escapeCode = 't'
                        mapped := "`t"
                    result .= mapped
                    position += 1
                    continue
                }
                if escapeCode = "u" && RegExMatch(SubStr(jsonText, position + 1, 4), "i)^[0-9a-f]{4}$") {
                    hex := SubStr(jsonText, position + 1, 4)
                    chrCode := "0x" . hex
                    result .= Chr(chrCode)
                    position += 5
                    continue
                }
                return false
            }
            result .= character
            position += 1
        }
        return false
    }

    ; Advance the parser position past JSON whitespace.
    static _SkipJsonWhitespace(jsonText, &position) {
        while (character := SubStr(jsonText, position, 1)) != "" && InStr(" `t`r`n", character)
            position += 1
    }

    ; Update one secret value in the active JSON file.
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

    ; Append a new non-secret definition to the tracked AHK catalog.
    static _SaveSecretDefinition(secretToSave) {
        propertyName := this._GetSecretKey(secretToSave)
        if propertyName = "" {
            Info("Can't add secret without property name:`n`n" . secretToSave.name, 5000)
            return false
        }

        ; Generate valid AHK source because names and descriptions can contain special characters.
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

    ; Resolve the stable catalog key belonging to a Secret instance.
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

    ; Safely replace a file through a fully written process-specific temporary file.
    static _WriteFile(filePath, content) {
        ; Write completely to a process-specific temp file before replacing the destination.
        tempPath := filePath . "." . DllCall("GetCurrentProcessId", "UInt") . "." . A_TickCount . ".tmp"
        try FileDelete(tempPath)
        try {
            FileAppend(content, tempPath, "UTF-8-RAW")
            ; Overwrite in one move; never delete the valid destination first.
            FileMove(tempPath, filePath, true)
        } catch as writeError {
            try FileDelete(tempPath)
            throw writeError
        }
    }

    ; Write the active secrets map to its configured JSON file.
    static _WriteSecrets(secrets) => this._WriteJsonFile(this.FILE_PATH, secrets)
    

    ; Serialize a map and safely write it as formatted JSON.
    static _WriteJsonFile(filePath, values) => this._WriteFile(filePath, JSON.stringify(values, unset, "    "))
    

    ; Convert arbitrary user text into a safe quoted AutoHotkey string literal.
    static _AhkStringLiteral(value) {
        ; Escape user text for inclusion inside a quoted AutoHotkey string literal.
        backtick := Chr(96)
        quote := Chr(34)
        escaped := StrReplace(value, backtick, backtick . backtick)
        escaped := StrReplace(escaped, "`r", backtick . "r")
        escaped := StrReplace(escaped, "`n", backtick . "n")
        escaped := StrReplace(escaped, "`t", backtick . "t")
        escaped := StrReplace(escaped, quote, backtick . quote)
        return quote . escaped . quote
    }

    ; Execute an operation exclusively across all cooperating AutoHotkey processes.
    static _WithFileLock(callback) {
        ; Every process using this name coordinates through the same Windows mutex.
        mutexHandle := DllCall("CreateMutex", "Ptr", 0, "Int", false, "Str", this.MUTEX_NAME, "Ptr")
        if !mutexHandle
            throw OSError()

        ; Wait until the other process finishes, but never wait indefinitely.
        waitResult := DllCall("WaitForSingleObject", "Ptr", mutexHandle, "UInt", this.MUTEX_TIMEOUT_MS, "UInt")
        ; 0 means acquired; 0x80 means acquired after the previous owner terminated.
        if waitResult != 0 && waitResult != 0x80 {
            DllCall("CloseHandle", "Ptr", mutexHandle)
            if waitResult = 0x102
                throw Error("Timed out waiting for access to the secrets files.")
            throw OSError()
        }

        try return callback.Call()
        finally {
            ; Always release ownership, including when parsing or writing throws an error.
            DllCall("ReleaseMutex", "Ptr", mutexHandle)
            DllCall("CloseHandle", "Ptr", mutexHandle)
        }
    }
}
