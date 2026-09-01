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

#Include <Tools\Info>
#Include <Core>
#Include Button.ahk
#Include Controller.ahk
#Include "..\..\Apps Integrated\Command Storer\Command Storer.ahk"
#Include ..\..\Apps Integrated\Spell Checker.ahk
#Include ..\..\Apps Integrated\Fake Working Mode.ahk
#Include <Apps\Spotify>
#Include <Apps\Notion>
#Include <Core\ErrorReporter>
#Include ..\..\Startup\Startup.ahk
#Include <Apps\Browser>
#Include <Core\CallbackAdapters>

; ===========================================================================
; === ACTIONS REGISTRATION ==================================================
; ===========================================================================
ToggleSpellChecker() => SpellChecker.Toggle()
GetSpellCheckerState() => SpellChecker.Enabled
KillAllAHkProcesses() => System.KillAllAHkProcesses()
ToggleFakeWorkMode() => FakeWorkMode.Toggle()
GetFakeWorkModeState() => FakeWorkMode.Enabled

OpenNotionShitFixen() => Notion.OpenPage(NotionPages.shitFixen)
CloseAllBrowsers() => (Info("Close all browsers"), Browser.CloseAll())

; ============================================================================
; === BUTTONS REGISTRATION ======================---==========================
; ============================================================================

buttons := [
    ToggleButton(ToggleSpellChecker, GetSpellCheckerState, "Spell Checker", "spell checker.gif"),
        Button((*) => ErrorReporter.Notify("Pizza Default", "Macro Board", "info"), "Pizza Default")
    Button(CommandStorer_ShowMainGui, "Command Storer", "tetris.gif"),
    ToggleButton(ToggleFakeWorkMode, GetFakeWorkModeState, "Fake Work Mode", "ai.gif"),
    Button(RunStartup, "Reload Startup")
] 

profileButtons := Map(
    Profiles.woonkamerLaptops, [
        Button(OpenNotionShitFixen, "S H I T  F I X E N", "notion.gif"),
        Button(StartSpotifyGoodMorningJazz, "Start Spotify Playlist", "spotify.gif"),
    ],
    Profiles.work, [
        Button(CloseAllBrowsers, "Kill Browsers", "game over.gif"),
    ],
    Profiles.default, [
        Button((*) => ErrorReporter.Notify("Pizza Default", "Macro Board", "info"), "Pizza Default")
    ]
)

buttons.Push(profileButtons.Get(ProfileManager.Current, [])*)
myMacroBoard := MacroBoard(buttons)
DesktopsDDL.PinApp(myMacroBoard.Hwnd)
CapsLock.Hotkey("Space", CallbackAdapters.MakeHotkeyHandler("macro_board.show", (*) => myMacroBoard.Show(), { serviceId: "macro_board" }))