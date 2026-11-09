; ============================================================================
; === Remote Board - Touch-friendly macro board while Parsec is connected =====
; ============================================================================
;
; [FEATURES]
;   - Appears as a floating, draggable bubble while a Parsec guest is connected
;     (phone or other laptop) and disappears when the last guest leaves
;   - Tap the bubble: the board fills the screen with every action; the
;     buttons grow or shrink to use all space, however many there are
;   - Tap the toggle tile (or press Esc) to collapse back to the bubble
;   - CapsLock+P shows or hides the bubble manually, also without Parsec
;   - The Macro Board's "Remote Board" button opens the full board directly
;     (RemoteBoardClient.Open(), see Remote Board Client.ahk)
;   - Djengus profile only
;
; [SETUP]
;   Add a RemoteButton(label, emoji, action) to the list below.
; ============================================================================

#Requires AutoHotkey v2
#SingleInstance Force
#Include ..\..\Lib\Core\OnError.ahk
#Include ..\..\Lib\Core\Paths.ahk
#Include ..\..\Lib\Core\Links.ahk
#Include ..\..\Lib\Helpers\Capslock.ahk
#Include ..\..\Profiles\Profile Manager.ahk
#Include ..\..\Lib\Apps\Parsec.ahk
#Include ..\..\Lib\Apps\PhilipsTv.ahk
#Include ..\..\Lib\Apps\Spotify.ahk
#Include ..\..\Lib\Apps\Woonkamer Scene.ahk
#Include ..\..\Apps Integrated\Suite Control\Suite Control.ahk
#Include Controller.ahk
#Include Remote Board Client.ahk

TraySetIcon(Paths.autoHotkeyIcon)

if !ProfileManager.Is(Profiles.djengus)
    ExitApp()

buttons := [
    RemoteButton("Tv aan", "📺", () => PhilipsTv.On()),
    RemoteButton("Tv uit", "🌙", () => PhilipsTv.Off()),
    RemoteButton("Woonkamer", "🔥", StartWoonkamerScene),
    RemoteButton("Good Morning Jazz", "🎷", StartSpotifyGoodMorningJazz),
    RemoteButton("YouTube", "▶️", () => Run(Links.youtube)),
    RemoteButton("Play / pauze", "⏯️", () => Send("{Media_Play_Pause}")),
    RemoteButton("Volgende", "⏭️", () => Send("{Media_Next}")),
    RemoteButton("Zachter", "🔉", () => Send("{Volume_Down 5}")),
    RemoteButton("Harder", "🔊", () => Send("{Volume_Up 5}")),
    RemoteButton("Geluid aan/uit", "🔇", () => Send("{Volume_Mute}")),
    RemoteButton("Herlaad AutoHotkey", "🔄", () => SuiteControl.ReloadSuite(false)),
]

board := RemoteBoard(buttons)

OnParsecChange(connected) {
    if connected
        board.ShowBubble()
    else
        board.HideBoard()
}
ParsecSessionWatcher(OnParsecChange).Start()

CapsLock.Hotkey("p", (*) => board.ToggleVisible())

; Open requests from other scripts (Macro Board button), also at launch.
OnMessage(RemoteBoardClient.OPEN_MESSAGE, (*) => (SetTimer(() => board.OpenBoard(), -1), 0))
for arg in A_Args
    if (arg = RemoteBoardClient.OPEN_ARGUMENT)
        board.OpenBoard()
