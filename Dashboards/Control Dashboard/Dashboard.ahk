#SingleInstance Force
Persistent(true)
#Include ..\..\Lib\Core\OnError.ahk
#Include ..\..\Lib\Core\Paths.ahk

TraySetIcon(Paths.autoHotkeyIcon)

myControlDashboard := ControlDashboard()
myControlDashboard.InitializeHidden()

OnMessage(0x8001, ShowRequestedControlDashboardSection)

ShowRequestedControlDashboardSection(sectionId, *) {
    sections := ["overview", "processes", "logs", "tests", "profiles", "health"]
    if (sectionId >= 1 && sectionId <= sections.Length)
        myControlDashboard.ShowSection(sections[sectionId])
}

#Include Control Dashboard.ahk
