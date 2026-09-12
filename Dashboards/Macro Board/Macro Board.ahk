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

#Include ..\..\Lib\Core\OnError.ahk
#Include ..\..\Lib\Core\Paths.ahk
#Include ..\..\Lib\Helpers\Capslock.ahk
#Include ..\..\Lib\Tools\Desktops DLL Library\Desktops DLL Library.ahk
#Include ..\..\Lib\Tools\Info.ahk
#Include ..\..\Profiles\Profile Manager.ahk
#Include Button.ahk
#Include Controller.ahk
#Include "..\..\Apps Integrated\Command Storer\Command Storer.ahk"
#Include ..\..\Apps Integrated\Spell Checker.ahk
#Include ..\..\Apps Integrated\Suite Control\Suite Control.ahk
#Include ..\..\Apps Integrated\Fake Working Mode.ahk
#Include "..\..\Apps Integrated\Notion Pages.ahk"
#Include ..\..\Lib\Apps\Spotify.ahk
#Include ..\..\Lib\Apps\Notion.ahk
#Include ..\..\Lib\Apps\Browser.ahk
#Include ..\Control Deck\Control Deck.ahk

; ===========================================================================
; === ACTIONS REGISTRATION ==================================================
; ===========================================================================
SpellChecker.Enable()
InitializeFakeWorkModeForProfile()

ToggleSpellChecker() => SpellChecker.Toggle()
GetSpellCheckerState() => SpellChecker.Enabled
KillAllAHkProcesses() => SuiteControl.ExitSuite()
ToggleFakeWorkMode() => FakeWorkMode.Toggle()
GetFakeWorkModeState() => FakeWorkMode.Enabled
PullAllWindowsToCurrentDesktop() => DesktopsDDL.PullAllWindowsToCurrentDesktop()
OpenNotionShitFixen() => Notion.OpenPage(NotionPages.shitFixen)
CloseAllBrowsers() => (Info("Close all browsers"), Browser.CloseAll())
KillAndReloadAllAHkProcesses() => SuiteControl.ReloadSuite()

; ============================================================================
; === BUTTONS REGISTRATION ======================---==========================
; ============================================================================

buttons := [
    Button(ShowControlDeck, "Control Deck", "control deck.gif"),
    Button(KillAndReloadAllAHkProcesses, "Reload AutoHotkey" , "control deck restart.gif"),
    Button(KillAllAHkProcesses, "Kill All AHK Processes", "control deck shutdown.gif"),
    Button(PullAllWindowsToCurrentDesktop, "Pull All Windows to Current Desktop", "Pull all windows to current desktop.gif"),
    ToggleButton(ToggleFakeWorkMode, GetFakeWorkModeState, "Fake Work Mode", "control deck fake work mode.gif"),
    ToggleButton(ToggleSpellChecker, GetSpellCheckerState, "Spell Checker", "spell check.gif"),
]

profileButtons := Map(
    Profiles.woonkamerLaptops, [
        Button(OpenNotionShitFixen, "S H I T  F I X E N", "notion.gif"),
        Button(StartSpotifyGoodMorningJazz, "Start Spotify Playlist", "spotify.gif"),
    ],
    Profiles.work, [
        Button(CloseAllBrowsers, "Kill Browsers", "game over.gif"),
        Button(CommandStorer_ShowMainGui, "Command Storer", "tetris.gif"),
    ],
    Profiles.default, [
        Button(MsgBox, "Pizza Default", "pizza.gif")
    ]
)

buttons.Push(profileButtons.Get(ProfileManager.Current, [])*)
myMacroBoard := MacroBoard(buttons)
DesktopsDDL.PinApp(myMacroBoard.Hwnd)
CapsLock.Hotkey("Space", (*) => myMacroBoard.Show())
