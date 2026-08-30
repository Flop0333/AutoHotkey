#Requires AutoHotkey v2

/** Canonical action definitions for application behaviors shared by consumers. */
class ApplicationActions {
    static VsCodeZoomIn() => Action("vscode.zoom-in", "Zoom In", (*) => Send("{Ctrl Down}{+}{Ctrl Up}"), {
        category: "VS Code", isAvailable: (*) => WinExist("ahk_exe Code.exe")
    })

    static VsCodeZoomOut() => Action("vscode.zoom-out", "Zoom Out", (*) => Send("{Ctrl Down}{-}{Ctrl Up}"), {
        category: "VS Code", isAvailable: (*) => WinExist("ahk_exe Code.exe")
    })

    static CalendarPreviousWeek() => Action("calendar.previous-week", "Previous Calendar Week", (*) => Send("k"), {
        category: "Calendar"
    })

    static CalendarNextWeek() => Action("calendar.next-week", "Next Calendar Week", (*) => Send("j"), {
        category: "Calendar"
    })

    static KeePassMainPassword(execute) => Action("keepass.main-password.insert", "Insert Main Password", execute, {
        category: "KeePass", profiles: ["Work"], tags: ["sensitive"]
    })

    static KeePassSecondaryPassword(execute) => Action("keepass.secondary-password.insert", "Insert Secondary Password", execute, {
        category: "KeePass", profiles: ["Work"], tags: ["sensitive"]
    })

    static NotionShitFixen(execute) => Action("notion.shit-fixen.open", "S H I T  F I X E N", execute, {
        category: "Notion", icon: "notion.gif", profiles: ["Woonkamer Laptops"]
    })

    static SpotifyGoodMorningJazz(execute) => Action("spotify.good-morning-jazz.start", "Start Spotify Playlist", execute, {
        category: "Media", icon: "spotify.gif", profiles: ["Woonkamer Laptops"]
    })

    static Finances(execute) => Action("personal.finances.open", "Financiën Sheet", execute, {
        category: "Personal", icon: "tetris.gif", profiles: ["Woonkamer Laptops"]
    })

    static Calendar(execute) => Action("calendar.open", "Calendar", execute, {
        category: "Productivity", icon: "calendar.gif", profiles: ["Woonkamer Laptops"]
    })

    static Maps(execute) => Action("maps.open", "Maps", execute, {
        category: "Personal", icon: "maps.gif", profiles: ["Woonkamer Laptops"]
    })

    static Weather(execute) => Action("weather.open", "Weer", execute, {
        category: "Personal", icon: "weer.gif", profiles: ["Woonkamer Laptops"]
    })

    static ChatGpt(execute) => Action("chatgpt.open", "ChatGPT", execute, {
        category: "AI", icon: "ai.gif", profiles: ["Woonkamer Laptops"]
    })

    static NotionWorkDashboard(execute) => Action("notion.work-dashboard.open", "VGZ Dashboard", execute, {
        category: "Notion", icon: "notion.gif", profiles: ["Work", "Dev Box"]
    })

    static CloseAllBrowsers(execute) => Action("browser.close-all", "Kill Browsers", execute, {
        description: "Close every Brave, Edge, and Chrome window", category: "System",
        icon: "game over.gif", profiles: ["Work"],
        confirmation: ActionConfirmation.Destructive("Close all browser windows?")
    })
}
