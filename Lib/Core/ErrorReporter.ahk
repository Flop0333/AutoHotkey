#Requires AutoHotkey v2
#Include ErrorRecord.ahk

/** Writes sanitized error diagnostics. User notifications belong to Notifier. */
class ErrorReporter {
    static MAX_LOG_BYTES := 2 * 1024 * 1024
    static LOG_KEEP_FILES := 5

    static GetLogDir() {
        localAppData := EnvGet("LOCALAPPDATA")
        if localAppData = ""
            localAppData := A_Temp
        return RTrim(localAppData, "\/") "\AutoHotkey Workflow\Logs"
    }

    static Report(thrown, message := "") {
        try {
            record := thrown is ErrorRecord ? thrown : ErrorRecord.FromThrown(thrown, message)
            if message != "" && record.message = ""
                record.message := message

            logDir := this.GetLogDir()
            DirCreate(logDir)
            logFile := logDir "\error.log.jsonl"

            try size := FileGetSize(logFile)
            catch
                size := 0

            if size > this.MAX_LOG_BYTES
                this._RotateLogs(logDir, "error.log.jsonl", this.LOG_KEEP_FILES)

            json := this._Redact(record).ToJson()
            FileAppend(json "`n", logFile, "UTF-8")
            return {ok: true, path: logFile, record: record}
        } catch as reportError {
            result := this._WriteFallback(reportError)
            result.record := thrown is ErrorRecord ? thrown : ErrorRecord.FromThrown(thrown, message)
            return result
        }
    }

    static _Redact(record) {
        copy := ErrorRecord()
        for name, value in record.OwnProps()
            copy.%name% := value

        clipboardText := ""
        try clipboardText := A_Clipboard

        for name, value in copy.OwnProps() {
            if Type(value) != "String"
                continue

            value := RegExReplace(value, "i)\b(?:https?|ftp|file)://\S+", "[REDACTED_URL]")
            value := RegExReplace(value, "i)Secrets\.[A-Za-z0-9_]+", "[REDACTED_SECRET]")
            if clipboardText != "" && StrLen(clipboardText) >= 4
                value := StrReplace(value, clipboardText, "[REDACTED_CLIPBOARD]")
            copy.%name% := value
        }

        return copy
    }

    static _WriteFallback(reportError) {
        try {
            fallbackPath := A_Temp "\error-reporter-fallback.jsonl"
            fallbackRecord := ErrorRecord.FromThrown(reportError, "Primary error reporting failed")
            FileAppend(fallbackRecord.ToJson() "`n", fallbackPath, "UTF-8")
            return {ok: false, fallback: fallbackPath, error: reportError.Message}
        } catch as fallbackError {
            return {ok: false, error: fallbackError.Message}
        }
    }

    static _RotateLogs(logDir, baseName, keepCount := 5) {
        try {
            source := logDir "\" baseName
            if !FileExist(source)
                return

            destination := logDir "\" StrReplace(baseName, ".jsonl", "") "." A_Now ".jsonl"
            FileMove(source, destination)

            files := []
            Loop Files, logDir "\" StrReplace(baseName, ".jsonl", "") ".*.jsonl", "F"
                files.Push({path: A_LoopFileFullPath, modified: A_LoopFileTimeModified})

            while files.Length > keepCount {
                oldestIndex := 1
                for index, fileInfo in files
                    if fileInfo.modified < files[oldestIndex].modified
                        oldestIndex := index
                try FileDelete(files[oldestIndex].path)
                files.RemoveAt(oldestIndex)
            }
        }
        ; Rotation is best-effort and must never prevent the current log write.
    }
}
