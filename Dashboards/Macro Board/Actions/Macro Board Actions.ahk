#Requires AutoHotkey v2

/** Registers shared actions currently exposed by Macro Board. */
class MacroBoardActions {
    static Register() {
        ActionRegistry.RegisterAll([
            ProductivityActions.SpellCheckerToggle((*) => SpellChecker.Toggle(), (*) => SpellChecker.Enabled),
            SystemActions.KillAhkProcesses((*) => KillAllAHkProcesses(true)),
            DevelopmentActions.CommandStorer(CommandStorer_ShowMainGui),
            ProductivityActions.FakeWorkToggle((*) => FakeWorkMode.Toggle(), (*) => FakeWorkMode.Enabled),
            SystemActions.ReloadStartup(RunStartup),
            ApplicationActions.NotionShitFixen((*) => Notion.OpenPage(NotionPages.shitFixen)),
            ApplicationActions.SpotifyGoodMorningJazz((*) => Spotify.StartPlaylist(Playlist.goodMorningJazz)),
            ApplicationActions.Finances(OpenFinancien),
            ApplicationActions.Calendar(OpenCalendar),
            ApplicationActions.Maps(OpenGoogleMaps),
            ApplicationActions.Weather(OpenWeer),
            ApplicationActions.ChatGpt(OpenAI),
            ApplicationActions.NotionWorkDashboard((*) => Notion.OpenPage(NotionPages.workDashboard)),
            ApplicationActions.CloseAllBrowsers(CloseAllBrowsers),
            Action("demo.pizza", "Pizza Default", (*) => MsgBox("Pizza Default"), {
                category: "Demo", profiles: ["Default"]
            })
        ], "Macro Board")
    }
}
