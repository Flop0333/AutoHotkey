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

#Include ..\..\Lib\Core.ahk
#Include ..\..\Lib\Actions\Modules\Window Actions.ahk
#Include Gesture Detector.ahk
CoordMode "Mouse", "Screen"

ActionRegistry.RegisterAll([
    WindowActions.MoveToLeftMonitor((*) => MoveWindowToMonitor("Left")),
    WindowActions.MoveToRightMonitor((*) => MoveWindowToMonitor("Right")),
    WindowActions.MaximizeUnderMouse(MaximizeWindow),
    WindowActions.MinimizeUnderMouse(MinimizeWindow)
], "Mouse Gestures")

GestureDetector() ; Initialize the gesture detector

class Gestures {
    static gestures := Map()
    
    static Add(gesturePattern, actionId) {
        ActionBinding.Require(actionId)
        this.gestures[gesturePattern] := actionId
    }
    static GetActionId(gesturePattern) => this.gestures.Has(gesturePattern) ? this.gestures[gesturePattern] : false
}

;=============================================================
;=== GESTURES REGISTRATION ===================================
;=============================================================
Gestures.Add("L", "window.move-to-left-monitor")
Gestures.Add("R", "window.move-to-right-monitor")
Gestures.Add("U", "window.maximize-under-mouse")
Gestures.Add("D", "window.minimize-under-mouse")


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
