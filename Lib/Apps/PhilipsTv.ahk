; ============================================================================
; === Philips TV - Power control through the tv-besturing PowerShell scripts ==
; ============================================================================
;
; [SETUP]
;   Pair once with Appbeheer/beheer/tv-besturing/tv-koppelen.ps1 (see its README).
;
; [USAGE]
;   PhilipsTv.On()
;   PhilipsTv.Off()
; ============================================================================

#Include ..\Tools\Info.ahk

class PhilipsTv {
    static scriptsDir := A_MyDocuments "\Appbeheer\beheer\tv-besturing"

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
        script := this.scriptsDir "\" scriptName
        if !FileExist(script) {
            Info("Tv-besturing van Appbeheer ontbreekt.")
            return
        }
        Run('powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "' script '"', , "Hide")
    }
}
