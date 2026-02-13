; ============================================================================
; === Button - Macro Board button data models ================================
; ============================================================================
;
; [USAGE]
;   Use the function names (as strings) to define button actions and states.
;
;   Example simple action button
;       btn := Button("OpenBrowser", "Open Chrome", "chrome.gif")
;   
;   Example toggle button with state
;       toggleBtn := ToggleButton(
;           "ToggleNightlight",
;           () => Nightlight.IsEnabled(),
;           "Night Light",
;           "moon.png"
;       )
;
; [BUTTON TYPES]
;   - Button: Standard action button that triggers a function
;   - ToggleButton: Button with on/off state, displays current state in UI
; ============================================================================

class Button {
    __New(funcName, tooltip, image := "") {
        this.funcName := funcName
        this.tooltip := tooltip
        this.image := image
        this.isToggle := false
    }
}

class ToggleButton extends Button {
    __New(funcName, getStateFunc, tooltip, image := "") {
        super.__New(funcName, tooltip, image?)
        this.getStateFunc := getStateFunc
        this.isToggle := true
    }
}