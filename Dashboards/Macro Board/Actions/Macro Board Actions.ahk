#Requires AutoHotkey v2

/** Registers shared actions currently exposed by Macro Board. */
class MacroBoardActions {
    static Register() {
        ActionRegistry.RegisterAll([
            Action("writing.spell-checker.toggle", "Spell Checker", ToggleSpellChecker, {
                description: "Enable or disable automatic spelling corrections", category: "Writing",
                icon: "spell checker.gif", getState: GetSpellCheckerState
            }),
            SystemActions.KillAhkProcesses((*) => KillAllAHkProcesses(true)),
            Action("development.command-storer.open", "Command Storer", CommandStorer_ShowMainGui, {
                description: "Open the saved command collection", category: "Development", icon: "tetris.gif"
            }),
            Action("productivity.fake-work-mode.toggle", "Fake Work Mode", ToggleFakeWorkMode, {
                description: "Enable or disable idle prevention", category: "Productivity",
                icon: "ai.gif", getState: GetFakeWorkModeState
            }),
            SystemActions.ReloadStartup(RunStartup),
            ApplicationActions.NotionShitFixen(OpenNotionShitFixen),
            ApplicationActions.SpotifyGoodMorningJazz(StartSpotifyGoodMorningJazz),
            ApplicationActions.Finances(OpenFinancien),
            ApplicationActions.Calendar(OpenCalendar),
            ApplicationActions.Maps(OpenGoogleMaps),
            ApplicationActions.Weather(OpenWeer),
            ApplicationActions.ChatGpt(OpenAI),
            ApplicationActions.NotionWorkDashboard(OpenNotionVGZDashboard),
            ApplicationActions.CloseAllBrowsers(CloseAllBrowsers),
            Action("demo.pizza", "Pizza Default", (*) => MsgBox("Pizza Default"), {
                category: "Demo", profiles: ["Default"]
            })
        ])
    }
}
