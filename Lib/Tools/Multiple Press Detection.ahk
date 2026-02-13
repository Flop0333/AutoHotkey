; ============================================================================
; === Multiple Press Detection ===============================================
; ============================================================================
;
; [EXAMPLE]
;   q::MultiplePressDetection([Once, Twice, ThreeTimes])
;   Once() => MsgBox("1 time!")
;   Twice() => MsgBox("2 times!")
;   ThreeTimes() => MsgBox("3 times!")
; ============================================================================


Class MultiplePressDetection {

    __New(actions := [Func]) => this.HandleMultiplePresses(actions)

    HandleMultiplePresses(actions) {
        amountPressed := 0
        While (A_Index > 1 ? "" : (RegExMatch(A_ThisHotkey, "i)(?:[~#!<>\*\+\^\$]*([^ ]+)( UP)?)$", &Key), amountPressed:= key.2? 1: 0), KeyWait(Key.1, "D T.3"))
            amountPressed++, KeyWait(Key.1)

        actions.Has(amountPressed) && actions[amountPressed] ? actions[amountPressed].Call() : ""
    }
}