; ============================================================================
; CapsLock as a Modifier Key for CapsLock-based hotkeys
; ============================================================================
; 
; [SETUP]
;   1. Run "Capslock Handler.ahk" first (handles global CapsLock behavior)
;   2. Include this file in your scripts
;
; [FEATURES]
;   - Hold CapsLock + Key for custom hotkeys
;   - Double-tap Toggle CapsLock state
;   - Works across multiple running scripts
;
; [USAGE]
;   Capslock.Hotkey("1", (*) => MsgBox("CapsLock + 1 pressed"))
; ============================================================================


class Capslock {
    static Hotkey(key, callback) {
      HotIf((*) => Capslock.IsPressed())
      Hotkey(key, callback)
      HotIf()
    }

   static IsPressed() => GetKeyState("CapsLock", "P")
}