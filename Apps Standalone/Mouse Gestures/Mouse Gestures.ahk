; ============================================================================
; === Mouse Gestures - Execute actions with mouse movements ==================
; ============================================================================
;
; [FEATURES]
; - Hold configured hotkey and move mouse in patterns to trigger actions
; - Draw directional gestures: Left (L), Right (R), Up (U), Down (D)
; - Chain multiple directions for complex gestures (e.g., "LU", "UR")
; - Visual feedback showing detected gesture pattern
; - Works on window under mouse cursor
;
; [DEFAULT GESTURES]
; - L: Move window to left monitor
; - R: Move window to right monitor
; - U: Maximize window
; - D: Minimize window
;
; [SETUP]
; - Add gestures using: Gestures.Add("pattern", (*) => YourAction())
; - Configure hotkey and sensitivity in Gesture Detector.ahk
; ============================================================================

#Include <Core>
#Include <Core\CallbackAdapters>
#Include Gesture Detector.ahk
CoordMode "Mouse", "Screen"

GestureDetector() ; Initialize the gesture detector

class Gestures {
    static gestures := Map()
    
    static Add(gesturePattern, command) => this.gestures[gesturePattern] := command
    static GetAction(gesturePattern) => this.gestures.Has(gesturePattern) ? this.gestures[gesturePattern] : false
}

;=============================================================
;=== GESTURES REGISTRATION ===================================
;=============================================================
Gestures.Add("L", CallbackAdapters.MakeHotkeyHandler("gesture.L", (*) => MoveWindowToMonitor("Left"), { serviceId: "mouse_gestures" }))
Gestures.Add("R", CallbackAdapters.MakeHotkeyHandler("gesture.R", (*) => MoveWindowToMonitor("Right"), { serviceId: "mouse_gestures" }))
Gestures.Add("U", CallbackAdapters.MakeHotkeyHandler("gesture.U", (*) => MaximizeWindow(), { serviceId: "mouse_gestures" }))
Gestures.Add("D", CallbackAdapters.MakeHotkeyHandler("gesture.D", (*) => MinimizeWindow(), { serviceId: "mouse_gestures" }))


;=============================================================
;=== CUSTOM FUNCTIONS ========================================
;=============================================================
GetWinUnderMouse() => (MouseGetPos(,,&windowUnderMouse), windowUnderMouse)

MoveWindowToMonitor(direction) {
    WinActivate(GetWinUnderMouse())
    Send "+#{" direction "}"
}

MinimizeWindow() => WinMinimize(GetWinUnderMouse())
MaximizeWindow() => WinMaximize(GetWinUnderMouse())

RestoreAllWindows() {
    winList := WinGetList()
    for winID in winList {
        state := WinGetMinMax("ahk_id " winID)
        if (state != 1)
            WinRestore "ahk_id " winID
    }
}