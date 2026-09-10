; Declarative startup inventory shared by Startup.ahk and the Control Dashboard.
; Keep ordering here: CapsLock Service must remain before its consumers.
#Include ..\..\Lib\Core\Paths.ahk

SuiteStartupScripts() => [
    Paths.appsStandalone "\Capslock Service.ahk",
    Paths.dashboards "\Age of Efficiency\Age of Efficiency.ahk",
    Paths.dashboards "\Macro Board\Macro Board.ahk",
    Paths.appsStandalone "\Desktops Manager\Desktops Manager.ahk",
    Paths.appsStandalone "\Emoji Sender\Emoji Sender.ahk",
    Paths.appsStandalone "\Mouse Gestures\Mouse Gestures.ahk",
    Paths.appsStandalone "\Screen Snipper\Screen Snipper.ahk",
    Paths.appsStandalone "\Key Bindings.ahk",
    Paths.appsStandalone "\Text Speaker\Text Speaker.ahk",
    Paths.appsStandalone "\Window Manager.ahk",
    Paths.appsIntegrated "\Command Storer\Command Storer.ahk",
    Paths.appsIntegrated "\App Hotkeys.ahk",
    Paths.appsIntegrated "\Hotkeys.ahk",
    Paths.appsIntegrated "\Mouse Toys.ahk"
]
