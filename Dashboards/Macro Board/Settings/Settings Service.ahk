#Include ..\..\..\Lib\Tools\IniService.ahk

class SettingsService extends IniService {

    __New(settingsPath) => super.__New(settingsPath)

    ReconstructIniFile() {
        ; Recreate the settings file with default values
        this.CreateSection("Window")
            .AddKeyValue("Window", "height", "240")
            .AddKeyValue("Window", "width", "420")
            .AddKeyValue("Window", "x", "560")
            .AddKeyValue("Window", "y", "70")
            .SaveFile()
    }
}
