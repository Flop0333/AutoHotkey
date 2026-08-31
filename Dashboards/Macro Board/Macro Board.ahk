; ============================================================================
; Macro Board Dashboard - Customizable for quick access to scripts and tools
; ============================================================================
;
; [FEATURES]
;   - Customizable buttons for various scripts and tools
;   - Profile-based button sets for different environments
;   - Easy access via configured hotkey
;   - Web-based frontend using WebView2
;
; [SETUP]
;   - Define buttons and their actions in the registration section below
;   - Put img/gif files in the icons folder (stream deck icons can be used)
; ============================================================================

#Include ..\..\Lib\Tools\Info.ahk
#Include ..\..\Lib\Core.ahk
#Include Button.ahk
#Include Controller.ahk
#Include "..\..\Apps Integrated\Command Storer\Command Storer.ahk"
#Include ..\..\Apps Integrated\Spell Checker.ahk
#Include ..\..\Apps Integrated\Kill All Ahk Processes.ahk
#Include ..\..\Apps Integrated\Fake Working Mode.ahk
#Include ..\..\Lib\Apps\Spotify.ahk
#Include ..\..\Lib\Apps\Notion.ahk
#Include ..\..\Startup\Startup.ahk
#Include ..\..\Lib\Actions\Modules\Application Actions.ahk
#Include ..\..\Lib\Actions\Modules\System Actions.ahk
#Include ..\..\Lib\Actions\Modules\Productivity Actions.ahk
#Include ..\..\Lib\Actions\Modules\Development Actions.ahk
#Include Actions\Macro Board Actions.ahk

MacroBoardActions.Register()

; ============================================================================
; === BUTTONS REGISTRATION ======================---==========================
; ============================================================================

buttons := [
    Button(ActionIds.Writing.SpellCheckerToggle),
    Button(ActionIds.System.KillAhkProcesses),
    Button(ActionIds.Development.CommandStorerOpen),
    Button(ActionIds.Productivity.FakeWorkToggle),
    Button(ActionIds.System.ReloadStartup)
] 

profileButtons := Map(
    Profiles.woonkamerLaptops, [
        Button(ActionIds.Application.NotionShitFixenOpen),
        Button(ActionIds.Application.SpotifyGoodMorningJazz),
        Button(ActionIds.Application.FinancesOpen),
        Button(ActionIds.Application.CalendarOpen),
        Button(ActionIds.Application.MapsOpen),
        Button(ActionIds.Application.WeatherOpen),
        Button(ActionIds.Application.ChatGptOpen),
    ],
    Profiles.work, [
        Button(ActionIds.Application.NotionWorkDashboardOpen),
        Button(ActionIds.Application.BrowserCloseAll),
    ],
    Profiles.devbox, [
        Button(ActionIds.Application.NotionWorkDashboardOpen)
    ],
    Profiles.default, [
        Button(ActionIds.Demo.Pizza)
    ]
)

buttons.Push(profileButtons.Get(ProfileManager.Current, [])*)
myMacroBoard := MacroBoard(buttons)
DesktopsDDL.PinApp(myMacroBoard.Hwnd)
CapsLock.Hotkey("Space", (*) => myMacroBoard.Show())
