; Declarative startup inventory and profile policy shared by Startup.ahk and
; the Control Deck. Keep ordering here: CapsLock Service must remain before
; its consumers.
#Include ..\..\Lib\Core\Paths.ahk

SuiteStartupScripts(profile := ProfileManager.current) {
    catalog := SuiteStartupScriptCatalog()
    excluded := SuiteStartupExcludedScriptIds(profile)
    scripts := []

    for script in catalog
        if !excluded.Has(script.id)
            scripts.Push(script.path)
    return scripts
}

; Add every auto-start application once, in launch order. Profiles below refer
; to these stable ids instead of duplicating paths or launch lists.
SuiteStartupScriptCatalog() => [
    {id: "capslockService", path: Paths.appsStandalone "\Capslock Service.ahk"},
    {id: "ageOfEfficiency", path: Paths.dashboards "\Age of Efficiency\Age of Efficiency.ahk"},
    {id: "macroBoard", path: Paths.dashboards "\Macro Board\Macro Board.ahk"},
    {id: "desktopsManager", path: Paths.appsStandalone "\Desktops Manager\Desktops Manager.ahk"},
    {id: "emojiSender", path: Paths.appsStandalone "\Emoji Sender\Emoji Sender.ahk"},
    {id: "mouseGestures", path: Paths.appsStandalone "\Mouse Gestures\Mouse Gestures.ahk"},
    {id: "screenSnipper", path: Paths.appsStandalone "\Screen Snipper\Screen Snipper.ahk"},
    {id: "keyBindings", path: Paths.appsStandalone "\Key Bindings.ahk"},
    {id: "textSpeaker", path: Paths.appsStandalone "\Text Speaker\Text Speaker.ahk"},
    {id: "windowManager", path: Paths.appsStandalone "\Window Manager.ahk"},
    {id: "commandStorer", path: Paths.appsIntegrated "\Command Storer\Command Storer.ahk"},
    {id: "appHotkeys", path: Paths.appsIntegrated "\App Hotkeys.ahk"},
    {id: "hotkeys", path: Paths.appsIntegrated "\Hotkeys.ahk"},
    {id: "mouseToys", path: Paths.appsIntegrated "\Mouse Toys.ahk"},
    ; Starts hidden, so the first time it is opened it is already loaded.
    {id: "controlDeck", path: Paths.dashboards "\Control Deck\Dashboard.ahk"},
    {id: "notionBoard", path: Paths.dashboards "\Notion Board\Notion Board.ahk"}
]

; The default policy is the full catalog. List exceptions only, keeping each
; profile's difference from that baseline visible and easy to change.
SuiteStartupExcludedScriptIds(profile) {
    if (profile = Profiles.esther) {
        allowed := Map("notionBoard", true)
        excluded := Map()
        for script in SuiteStartupScriptCatalog()
            if !allowed.Has(script.id)
                excluded[script.id] := true
        return excluded
    }

    if (profile = Profiles.work)
        return Map("desktopsManager", true, "notionBoard", true)
    if (profile = Profiles.devbox || profile = Profiles.default)
        return Map("notionBoard", true)
    return Map()
}
