; Minimal ErrorRecord model for Error Resilience (initial implementation)
#Include <Extensions\Json>

Class ErrorRecord {
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

    static FromThrown(thrown, params := {}) {
        r := ErrorRecord()
        ; copy optional params
        for k, v in params
            r[k] := v

        try {
            if IsObject(thrown) {
                if (thrown.HasOwnProp && thrown.HasOwnProp('message'))
                    r.errorMessage := thrown.message
                else if (IsFunc(thrown.ToString))
                    r.errorMessage := thrown.ToString()
                else
                    r.errorMessage := thrown
                if (thrown.HasOwnProp && thrown.HasOwnProp('stack'))
                    r.stack := thrown.stack
            } else {
                r.errorMessage := thrown
            }
        } catch {
            r.errorMessage := "<unserializable thrown value>"
        }

        r.fingerprint := r._Fingerprint()
        return r
    }

    _Fingerprint() {
        ; Simple deterministic fingerprint: 32-bit additive hash over key fields
        s := this.errorMessage "|" this.errorType "|" this.serviceId
        hash := 2166136261
        for i, ch in StrSplit(s, '')
            hash := (hash * 16777619) ^ Asc(ch)
        return Format("%08X", hash & 0xFFFFFFFF)
    }

    ToJson() {
        try {
            return Json.Stringify(this)
        } catch {
            ; Fallback naive serializer
            props := []
            for k, v in this
                try {
                    props.Push('"' k '": "' StrReplace(v, '"', '\\"') '"')
                } catch {
                    ; ignore property if it fails
                }
            return "{" StrJoin(props, ',') "}"
        }
    }
}
