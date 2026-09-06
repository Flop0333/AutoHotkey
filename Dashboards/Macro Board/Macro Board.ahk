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

#Include ..\..\Lib\Core.ahk
#Include Button.ahk
#Include Controller.ahk
#Include "..\..\Apps Integrated\Command Storer\Command Storer.ahk"
#Include ..\..\Apps Integrated\Spell Checker.ahk
#Include ..\..\Apps Integrated\Fake Working Mode.ahk
#Include ..\..\Lib\Apps\Spotify.ahk
#Include ..\..\Lib\Apps\Notion.ahk
#Include ..\..\Startup\Startup.ahk
#Include ..\..\Lib\Apps\Browser.ahk
#Include ..\Log Dashboard\Log Dashboard.ahk

; ===========================================================================
; === ACTIONS REGISTRATION ==================================================
; ===========================================================================
ToggleSpellChecker() => SpellChecker.Toggle()
GetSpellCheckerState() => SpellChecker.Enabled
KillAllAHkProcesses() => System.KillAllAHkProcesses()
ToggleFakeWorkMode() => FakeWorkMode.Toggle()
GetFakeWorkModeState() => FakeWorkMode.Enabled
PullAllWindowsToCurrentDesktop() => DesktopsDDL.PullAllWindowsToCurrentDesktop()
OpenNotionShitFixen() => Notion.OpenPage(NotionPages.shitFixen)
CloseAllBrowsers() => (Info("Close all browsers"), Browser.CloseAll())

; ============================================================================
; === BUTTONS REGISTRATION ======================---==========================
; ============================================================================

buttons := [
    Button(ShowLogDashboard, "Log Dashboard", "log dashboard.gif"),
    Button(RunStartup, "Reload AutoHotkey" , "Reload button.gif"),
    Button(KillAllAHkProcesses, "Kill All AHK Processes", "Kill all AHK processes.gif"),
    Button(PullAllWindowsToCurrentDesktop, "Pull All Windows to Current Desktop", "Pull all windows to current desktop.gif"),
    ToggleButton(ToggleFakeWorkMode, GetFakeWorkModeState, "Fake Work Mode", "ai.gif"),
    ToggleButton(ToggleSpellChecker, GetSpellCheckerState, "Spell Checker", "spell checker.gif"),
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
        Button(MsgBox, "Pizza Default")
    ]
)

buttons.Push(profileButtons.Get(ProfileManager.Current, [])*)
myMacroBoard := MacroBoard(buttons)
DesktopsDDL.PinApp(myMacroBoard.Hwnd)
CapsLock.Hotkey("Space", (*) => myMacroBoard.Show())