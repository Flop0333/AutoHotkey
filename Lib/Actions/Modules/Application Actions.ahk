#Requires AutoHotkey v2

/**
 * Canonical metadata factories for application behavior shared by consumers.
 * Most implementations are injected; tiny dependency-free Send actions stay inline.
 */
class ApplicationActions {
    static NotionSidebarToggle(execute) => Action(ActionIds.Application.NotionSidebarToggle, "Toggle Notion Sidebar", execute, {category: "Notion"})
    static TeamsMicrophoneToggle(execute) => Action(ActionIds.Application.TeamsMicrophoneToggle, "Mute or Unmute Teams", execute, {category: "Teams"})
    static VsCodePrimaryAction(execute) => Action(ActionIds.Application.VsCodePrimaryAction, "Run Primary Project Action", execute, {category: "VS Code"})
    static VsCodeSecondaryAction(execute) => Action(ActionIds.Application.VsCodeSecondaryAction, "Run Secondary Project Action", execute, {category: "VS Code"})
    static WhatsAppLaunch(execute, isAvailable := unset) => Action(ActionIds.Application.WhatsAppOpen, "WhatsApp", execute, {
        description: "Open or activate WhatsApp", category: "Communication",
        profiles: ["Woonkamer Laptops"], isAvailable: IsSet(isAvailable) ? isAvailable : (*) => true
    })
    static SpotifyLaunch(execute) => Action(ActionIds.Application.SpotifyOpen, "Spotify", execute, {
        description: "Open or activate Spotify", category: "Media", profiles: ["Woonkamer Laptops"]
    })
    static NotionLaunch(execute) => Action(ActionIds.Application.NotionOpen, "Notion", execute, {
        description: "Open or activate Notion", category: "Notion", profiles: ["Woonkamer Laptops"]
    })
    static VsCodeLaunch(execute) => Action(ActionIds.Application.VsCodeOpen, "Visual Studio Code", execute, {
        description: "Open or activate Visual Studio Code", category: "VS Code", profiles: ["Woonkamer Laptops"]
    })
    static VsCodeAutoHotkey(execute) => Action(ActionIds.Application.VsCodeAutoHotkeyOpen, "Open AutoHotkey in VS Code", execute, {
        description: "Open this AutoHotkey workspace in Visual Studio Code", category: "VS Code", profiles: ["Woonkamer Laptops"]
    })

    static VsCodeZoomIn() => Action(ActionIds.Application.VsCodeZoomIn, "Zoom In", (*) => Send("{Ctrl Down}{+}{Ctrl Up}"), {
        category: "VS Code", isAvailable: (*) => WinExist("ahk_exe Code.exe")
    })

    static VsCodeZoomOut() => Action(ActionIds.Application.VsCodeZoomOut, "Zoom Out", (*) => Send("{Ctrl Down}{-}{Ctrl Up}"), {
        category: "VS Code", isAvailable: (*) => WinExist("ahk_exe Code.exe")
    })

    static CalendarPreviousWeek() => Action(ActionIds.Application.CalendarPreviousWeek, "Previous Calendar Week", (*) => Send("k"), {
        category: "Calendar"
    })

    static CalendarNextWeek() => Action(ActionIds.Application.CalendarNextWeek, "Next Calendar Week", (*) => Send("j"), {
        category: "Calendar"
    })

    static KeePassMainPassword(execute) => Action(ActionIds.Application.KeePassMainPassword, "Insert Main Password", execute, {
        category: "KeePass", profiles: ["Work"], tags: ["sensitive"]
    })

    static KeePassSecondaryPassword(execute) => Action(ActionIds.Application.KeePassSecondaryPassword, "Insert Secondary Password", execute, {
        category: "KeePass", profiles: ["Work"], tags: ["sensitive"]
    })

    static NotionShitFixen(execute) => Action(ActionIds.Application.NotionShitFixenOpen, "S H I T  F I X E N", execute, {
        category: "Notion", icon: "notion.gif", profiles: ["Woonkamer Laptops"]
    })

    static SpotifyGoodMorningJazz(execute) => Action(ActionIds.Application.SpotifyGoodMorningJazz, "Start Spotify Playlist", execute, {
        category: "Media", icon: "spotify.gif", profiles: ["Woonkamer Laptops"]
    })

    static Finances(execute) => Action(ActionIds.Application.FinancesOpen, "Financiën Sheet", execute, {
        category: "Personal", icon: "tetris.gif", profiles: ["Woonkamer Laptops"]
    })

    static Calendar(execute) => Action(ActionIds.Application.CalendarOpen, "Calendar", execute, {
        category: "Productivity", icon: "calendar.gif", profiles: ["Woonkamer Laptops"]
    })

    static Maps(execute) => Action(ActionIds.Application.MapsOpen, "Maps", execute, {
        category: "Personal", icon: "maps.gif", profiles: ["Woonkamer Laptops"]
    })

    static Weather(execute) => Action(ActionIds.Application.WeatherOpen, "Weer", execute, {
        category: "Personal", icon: "weer.gif", profiles: ["Woonkamer Laptops"]
    })

    static ChatGpt(execute) => Action(ActionIds.Application.ChatGptOpen, "ChatGPT", execute, {
        category: "AI", icon: "ai.gif", profiles: ["Woonkamer Laptops"]
    })

    static NotionWorkDashboard(execute) => Action(ActionIds.Application.NotionWorkDashboardOpen, "VGZ Dashboard", execute, {
        category: "Notion", icon: "notion.gif", profiles: ["Work", "Dev Box"]
    })

    static CloseAllBrowsers(execute) => Action(ActionIds.Application.BrowserCloseAll, "Kill Browsers", execute, {
        description: "Close every Brave, Edge, and Chrome window", category: "System",
        icon: "game over.gif", profiles: ["Work"],
        confirmation: ActionConfirmation.Destructive("Close all browser windows?")
    })
}
