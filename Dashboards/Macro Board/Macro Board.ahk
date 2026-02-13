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
#Include ..\..\Apps Integrated\Spell Checker.ahk
#Include ..\..\Apps Integrated\Kill All Ahk Processes.ahk
#Include ..\..\Apps Integrated\Fake Working Mode.ahk
#Include ..\..\Lib\Apps\Spotify.ahk
#Include ..\..\Lib\Apps\Notion.ahk

; ============================================================================
; === BUTTONS REGISTRATION ======================---==========================
; ============================================================================

buttons := [
    ToggleButton(ToggleSpellChecker, GetSpellCheckerState, "Spell Checker", "spell checker.gif"),
    Button(KillAllAHkProcesses, "Kill All AHK Processes", "game over.gif"),
]

profileButtons := Map(
    Profiles.woonkamerLaptops, [
        Button(OpenNotionShitFixen, "S H I T  F I X E N", "notion.gif"),
        Button(StartSpotifyGoodMorningJazz, "Start Spotify Playlist", "spotify.gif"),
        Button(OpenFinancien, "Financiën Sheet", "tetris.gif"),
        Button(OpenCalendar, "Calendar", "calendar.gif"),
        Button(OpenGoogleMaps, "Maps", "maps.gif"),
        Button(OpenWeer, "Weer", "weer.gif"),
        Button(OpenAI, "ChatGpt", "ai.gif"),
    ],
    Profiles.work, [
        ToggleButton(ToggleFakeWorkMode, GetFakeWorkModeState, "Fake Work Mode", "ai.gif"),
        Button(OpenNotionVGZDashboard, "VGZ Dashboard", "notion.gif"),
    ],
    Profiles.devbox, [
        ToggleButton(ToggleFakeWorkMode, GetFakeWorkModeState, "Fake Work Mode", "ai.gif"),
    ],
    Profiles.default, [
        Button(Msgbox, "Pizza Default")
    ]
)

buttons.Push(profileButtons.Get(ProfileManager.Current, [])*)
myMacroBoard := MacroBoard(buttons)
DesktopsDDL.PinApp(myMacroBoard.Hwnd)
CapsLock.Hotkey("Space", (*) => myMacroBoard.Show())