; ============================================================================
; === Philips TV - Power control through the tv-besturing PowerShell scripts ==
; ============================================================================
;
; [SETUP]
;   Pair once with Tools/tv-besturing/tv-koppelen.ps1 (see its README).
;
; [USAGE]
;   PhilipsTv.On()
;   PhilipsTv.Off()
; ============================================================================

#Include ..\Core\Paths.ahk
#Include ..\Tools\Info.ahk

class PhilipsTv {
    static scriptsDir := Paths.tools "\tv-besturing"

    static On() {
        Info("Tv aanzetten...", 5000)
        this._RunScript("tv-aan.ps1")
    }

    static Off() {
        Info("Tv uitzetten...")
        this._RunScript("tv-uit.ps1")
    }

    ; Runs hidden and without waiting: switching on can take ~20 seconds.
    static _RunScript(scriptName) {
        Run('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' this.scriptsDir "\" scriptName '"', , "Hide")
    }
}
