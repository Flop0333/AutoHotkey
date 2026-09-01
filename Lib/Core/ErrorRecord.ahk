#Requires AutoHotkey v2

/** Sanitizable diagnostic data for a single failure. */
class ErrorRecord {
    __New() {
        this.time := A_Now
        this.severity := "error"
        this.category := "unknown"
        this.serviceId := ""
        this.operationId := ""
        this.safeMessage := ""
        this.errorType := ""
        this.errorMessage := ""
        this.what := ""
        this.file := ""
        this.line := 0
        this.stack := ""
        this.mode := ""
        this.durationMs := 0
        this.fingerprint := ""
    }

    static FromThrown(thrown, params := unset) {
        record := ErrorRecord()
        record.errorType := Type(thrown)

        if IsObject(thrown) {
            record.errorMessage := this._ReadProperty(thrown, "Message", "<object thrown>")
            record.what := this._ReadProperty(thrown, "What")
            record.file := this._ReadProperty(thrown, "File")
            record.line := this._ReadProperty(thrown, "Line", 0)
            record.stack := this._ReadProperty(thrown, "Stack")
        } else {
            try record.errorMessage := String(thrown)
            catch
                record.errorMessage := "<unserializable thrown value>"
        }

        if IsSet(params)
            this._ApplyParams(record, params)

        record.fingerprint := record._Fingerprint()
        return record
    }

    _Fingerprint() {
        ; 32-bit FNV-1a over stable fields.
        source := this.errorMessage "|" this.errorType "|" this.serviceId "|" this.operationId
        hash := 2166136261
        Loop Parse source
            hash := ((hash ^ Ord(A_LoopField)) * 16777619) & 0xFFFFFFFF
        return Format("{:08X}", hash)
    }

    ToJson() {
        properties := []
        for name, value in this.OwnProps()
            properties.Push(ErrorRecord._JsonString(name) ":" ErrorRecord._JsonValue(value))
        return "{" ErrorRecord._Join(properties, ",") "}"
    }

    static _ApplyParams(record, params) {
        if params is Map {
            for name, value in params
                record.%name% := value
            return
        }

        if IsObject(params)
            for name, value in params.OwnProps()
                record.%name% := value
    }

    static _ReadProperty(value, name, fallback := "") {
        try {
            if HasProp(value, name)
                return value.%name%
        }
        return fallback
    }

    static _JsonValue(value) {
        switch Type(value) {
            case "Integer", "Float":
                return String(value)
            case "String":
                return this._JsonString(value)
            default:
                return this._JsonString("<" Type(value) ">")
        }
    }

    static _JsonString(value) {
        value := String(value)
        value := StrReplace(value, "\", "\\")
        value := StrReplace(value, '"', '\"')
        value := StrReplace(value, "`r", "\r")
        value := StrReplace(value, "`n", "\n")
        value := StrReplace(value, "`t", "\t")
        return '"' value '"'
    }

    static _Join(values, separator) {
        result := ""
        for index, value in values
            result .= (index = 1 ? "" : separator) value
        return result
    }
}
