; ============================================================================
; === Double Tap - Hotkeys that fire on a quick double press ==================
; ============================================================================
;
; [FEATURES]
;   - Double tap within DoubleTap.interval ms runs the callback
;   - A single tap is replayed as the original key once the window has passed,
;     so the key keeps its normal behavior (at the cost of a short delay)
;   - Same press-release-press detection as the CapsLock Service toggle
;
; [USAGE]
;   DoubleTap.Hotkey("F1", () => MsgBox("F1 double tapped"))
; ============================================================================

class DoubleTap {
    static interval := 250 ; milliseconds between the two presses

    static Hotkey(key, callback) {
        ; $ forces the keyboard hook so the replayed single tap does not
        ; trigger this hotkey again.
        Hotkey("$" key, (*) => this._Handle(key, callback))
    }

    static _Handle(key, callback) {
        KeyWait(key)                                            ; wait for release
        if (A_TimeSinceThisHotkey < this.interval               ; short first press
            and KeyWait(key, "D T" this.interval / 1000)) {     ; and pressed again in time
            KeyWait(key)
            callback()
            return
        }
        Send("{Blind}{" key "}")                                ; single tap: original key
    }
}
