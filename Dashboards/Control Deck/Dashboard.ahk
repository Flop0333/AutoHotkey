#SingleInstance Force
Persistent(true)
#Include ..\..\Lib\Core\OnError.ahk
#Include ..\..\Lib\Core\Paths.ahk

TraySetIcon(Paths.autoHotkeyIcon)

myControlDeck := ControlDeck()
myControlDeck.InitializeHidden()

OnMessage(0x8001, ShowRequestedControlDeckSection)

ShowRequestedControlDeckSection(sectionId, *) {
    sections := ["overview", "processes", "logs", "tests", "profiles", "health"]
    if (sectionId >= 1 && sectionId <= sections.Length)
        myControlDeck.ShowSection(sections[sectionId])
}

#Include Control Deck.ahk
