; Minimal ErrorReporter skeleton (non-recursive, safe fallback)
#Include <Core\ErrorRecord>

; Log rotation + redaction defaults
MAX_LOG_BYTES := 2 * 1024 * 1024 ; rotate at ~2 MiB
LOG_KEEP_FILES := 5

Class ErrorReporter {
    static GetLogDir() {
        localApp := EnvGet("LOCALAPPDATA")
        if (localApp = "")
            localApp := A_Temp
        return RTrim(localApp, "\\/") "\\AutoHotkey Workflow\\Logs"
    }

    static Report(rec) {
        try {
            if (!IsObject(rec))
                rec := ErrorRecord.FromThrown(rec)

            logDir := this.GetLogDir()
            FileCreateDir(logDir)
            logFile := logDir "\\error.log.jsonl"

            ; Rotate if needed
            try size := FileGetSize(logFile) 
            catch {
                size := 0
                }
            if (size > MAX_LOG_BYTES)
                this._RotateLogs(logDir, "error.log.jsonl", LOG_KEEP_FILES)

            ; Redact sensitive fields before writing
            redacted := this._Redact(rec)
            FileAppend(redacted "`n", logFile, "utf-8")
            return { ok: true, path: logFile }
        } catch {
            ; Fallback: try temp file and avoid recursion
            try {
                tmp := A_Temp "\\error-reporter-fallback.jsonl"
                FileAppend((IsObject(rec) ? rec.ToJson() : "{\\message\\:\\\report-failed\\\}") "`n", tmp, "utf-8")
                return { ok: false, fallback: tmp, error: e.Message }
            } catch e2 {
                ; Last resort: swallow and return failure
                return { ok: false, error: e2.Message }
            }
        }
    }

    static Notify(message, title := "AutoHotkey", severity := "info", seconds := 5) {
        try {
            ; Non-modal native tray notification fallback
            ; Use TrayTip if available, otherwise ToolTip
            if (IsFunc(&TrayTip)) {
                TrayTip(title, message, seconds)
            } else {
                ToolTip(message)
                SetTimer(() => ToolTip(), - seconds * 1000)
            }

            ; Also write a short log entry
            rec := ErrorRecord.FromThrown(message, { serviceId: "", severity: severity, category: "notification", safeMessage: message })
            this.Report(rec)
            return { ok: true }
        } catch {
            return { ok: false, error: e.Message }
        }
    }

    static _Redact(rec) {
        ; Create a shallow copy and redact fields containing URLs or clipboard
        try {
            copy := {}
            for k, v in rec
                copy[k] := v

            ; redact common URL patterns in string fields
            urlPattern := "https?://\S+|ftp://\S+|file://\S+"
            for field in ["errorMessage", "safeMessage", "stack", "what"] {
                var := copy[field]
                if (IsSet(var) && var != "")
                    copy[field] := RegExReplace(var, urlPattern, "[REDACTED_URL]")
            }

            ; Redact clipboard contents if present
            try clip := A_Clipboard 
            catch {
                clip := ""
            }
            if (clip != "") {
                for k, v in copy
                    if IsString(v) && InStr(v, clip)
                        copy[k] := StrReplace(v, clip, "[REDACTED_CLIPBOARD]")
            }

            ; Redact simple secret token patterns (Secrets.PropertyName)
            for k, v in copy
                if IsString(v)
                    copy[k] := RegExReplace(copy[k], "Secrets\.[A-Za-z0-9_]+", "[REDACTED_SECRET]")

            ; Serialize
            return IsObject(copy) ? Json.Stringify(copy) : (IsFunc(copy.ToJson) ? copy.ToJson() : "{\\message\\:\\ redaction-failed}")
        } catch {
            return "redaction-error"
            ; return "{\"message\":\"redaction-error\"}"zz
        }
    }

    static _RotateLogs(logDir, baseName, keepCount := 5) {
        try {
            src := logDir "\\" baseName
            if !FileExist(src)
                return

            timestamp := A_Now
            dest := logDir "\\" StrReplace(baseName, ".jsonl", "") "." timestamp ".jsonl"
            FileMove(src, dest)

            ; Prune older rotated files, keep latest `keepCount` files
            files := []
            Loop Files, logDir "\\" StrReplace(baseName, ".jsonl", "") ".*.jsonl", "D"
                files.Push(A_LoopFileFullPath)

            ; If more than keepCount, delete oldest by modified time
            if (files.Length > keepCount) {
                ; find files to delete until length == keepCount
                while (files.Length > keepCount) {
                    oldest := ""
                    oldestTime := ""
                    for index, f in files {
                        try t := FileGetTime(f, "M") 
                        catch {
                            t := ""
                        }
                        if (oldest = "" || t < oldestTime) {
                            oldest := f
                            oldestTime := t
                        }
                    }
                    if (oldest != "") {
                        FileDelete(oldest)
                        ; remove from array
                        newFiles := []
                        for index, f in files
                            if (f != oldest)
                                newFiles.Push(f)
                        files := newFiles
                    } else
                        break
                }
            }
        } catch {
            ; swallow rotation errors to avoid cascading failures
        }
    }
}
