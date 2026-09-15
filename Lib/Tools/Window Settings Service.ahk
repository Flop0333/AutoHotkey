#Include IniService.ahk

; Persists a window's restored position and dimensions in an INI file selected
; by the owning application. The application also supplies its own defaults.
class WindowSettingsService extends IniService {
    __New(settingsPath, defaultWidth, defaultHeight, defaultX, defaultY) {
        this.defaultWidth := defaultWidth
        this.defaultHeight := defaultHeight
        this.defaultX := defaultX
        this.defaultY := defaultY
        super.__New(settingsPath)
    }

    ReconstructIniFile() {
        this.CreateSection("Window")
            .AddKeyValue("Window", "height", this.defaultHeight)
            .AddKeyValue("Window", "width", this.defaultWidth)
            .AddKeyValue("Window", "x", this.defaultX)
            .AddKeyValue("Window", "y", this.defaultY)
            .SaveFile()
    }
}
