; ============================================================================
; === Button - Macro Board button data models ================================
; ============================================================================
;
; [USAGE]
;   Reference one registered action ID. Tooltip and image are optional
;   Macro Board-specific overrides of shared action metadata.
;
;   btn := Button(ActionIds.Application.BrowserCloseAll, "Close Browsers", "chrome.gif")
; ============================================================================

class Button {
    __New(actionId, tooltip := "", image := "") {
        this.actionId := actionId
        this.tooltip := tooltip
        this.image := image
    }
}
