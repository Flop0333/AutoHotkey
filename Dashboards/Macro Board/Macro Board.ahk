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
    Button("writing.spell-checker.toggle"),
    Button("system.kill-ahk-processes"),
    Button("development.command-storer.open"),
    Button("productivity.fake-work-mode.toggle"),
    Button("system.reload-startup")
] 

profileButtons := Map(
    Profiles.woonkamerLaptops, [
        Button("notion.shit-fixen.open"),
        Button("spotify.good-morning-jazz.start"),
        Button("personal.finances.open"),
        Button("calendar.open"),
        Button("maps.open"),
        Button("weather.open"),
        Button("chatgpt.open"),
    ],
    Profiles.work, [
        Button("notion.work-dashboard.open"),
        Button("browser.close-all"),
    ],
    Profiles.devbox, [
        Button("notion.work-dashboard.open")
    ],
    Profiles.default, [
        Button("demo.pizza")
    ]
)

buttons.Push(profileButtons.Get(ProfileManager.Current, [])*)
myMacroBoard := MacroBoard(buttons)
DesktopsDDL.PinApp(myMacroBoard.Hwnd)
CapsLock.Hotkey("Space", (*) => myMacroBoard.Show())
