; ============================================================================
; === Parsec - Detect when someone is connected to this host ==================
; ============================================================================
;
; [HOW]
;   The Parsec host (parsecd.exe) logs every guest session to log.txt:
;       [I 2026-11-08 23:10:58] Name#1234 connected.
;       [I 2026-11-08 23:11:11] Name#1234 disconnected.
;   ParsecSessions counts the guests from those lines. ParsecSessionWatcher
;   polls only the newly appended part of the log and reports changes.
;
; [ROBUSTNESS]
;   - A truncated or replaced log is read again from the start.
;   - When parsecd.exe is not running, nobody can be connected, so a missing
;     "disconnected." line (crash) never leaves the state stuck.
;
; [USAGE]
;   watcher := ParsecSessionWatcher((connected) => ToolTip(connected))
;   watcher.Start()
; ============================================================================

; Pure guest bookkeeping, fed with log text. Kept free of file and process
; access so it can be unit tested.
class ParsecSessions {
    static LINE_PATTERN := "^\[\w [^\]]+\] (.+#\d+) (connected|disconnected)\.\s*$"

    __New() => this.guests := Map()

    Count => this.guests.Count
    IsConnected => this.guests.Count > 0

    Reset() => this.guests.Clear()

    ; Applies complete log lines; returns true when the connected state changed.
    Apply(text) {
        wasConnected := this.IsConnected
        for line in StrSplit(text, "`n", "`r") {
            if !RegExMatch(line, ParsecSessions.LINE_PATTERN, &match)
                continue
            if (match[2] = "connected")
                this.guests[match[1]] := true
            else if this.guests.Has(match[1])
                this.guests.Delete(match[1])
        }
        return wasConnected != this.IsConnected
    }
}

class ParsecSessionWatcher {
    static LOG_CANDIDATES := [
        A_AppDataCommon "\Parsec\log.txt", ; shared (service) install
        A_AppData "\Parsec\log.txt"        ; per-user install
    ]

    ; onChange is called with true/false whenever the connected state changes.
    __New(onChange, intervalMs := 1500) {
        this.onChange := onChange
        this.intervalMs := intervalMs
        this.sessions := ParsecSessions()
        this.logPath := ""
        this.offset := 0
        this.pending := "" ; incomplete last line, finished by the next poll
        this.timer := ObjBindMethod(this, "Poll")
    }

    IsConnected => this.sessions.IsConnected

    Start() {
        this.Poll()
        SetTimer(this.timer, this.intervalMs)
        return this
    }

    Stop() => SetTimer(this.timer, 0)

    Poll() {
        wasConnected := this.sessions.IsConnected
        if !ProcessExist("parsecd.exe")
            this._Restart("")
        else
            this._ReadNewLines()
        if (wasConnected != this.sessions.IsConnected)
            this.onChange.Call(this.sessions.IsConnected)
    }

    _ReadNewLines() {
        path := ParsecSessionWatcher.FindLog()
        if (path = "")
            return this._Restart("")
        if (path != this.logPath)
            this._Restart(path)

        try {
            file := FileOpen(path, "r", "UTF-8")
            if (file.Length < this.offset) { ; truncated or replaced
                this._Restart(path)
            }
            file.Pos := this.offset
            text := this.pending file.Read()
            this.offset := file.Length
            file.Close()
        } catch
            return

        lastNewline := InStr(text, "`n", , -1)
        this.pending := SubStr(text, lastNewline + 1)
        if lastNewline
            this.sessions.Apply(SubStr(text, 1, lastNewline))
    }

    _Restart(path) {
        this.sessions.Reset()
        this.logPath := path
        this.offset := 0
        this.pending := ""
    }

    ; The most recently written log wins when both install types exist.
    static FindLog() {
        newest := "", newestTime := ""
        for path in ParsecSessionWatcher.LOG_CANDIDATES {
            if !FileExist(path)
                continue
            modified := FileGetTime(path, "M")
            if (newest = "" || modified > newestTime)
                newest := path, newestTime := modified
        }
        return newest
    }
}
