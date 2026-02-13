#SingleInstance Force
#Include App.ahk
#Include ..\Tools\UIA-v2\Lib\UIA.ahk
#Include ..\Tools\Info.ahk

OpenNotionShitFixen() => Notion.OpenPage(NotionPages.shitFixen)
OpenNotionVGZDashboard() => Notion.OpenPage(NotionPages.workDashboard)


class NotionPages {
    static shitFixen := { title: "S H I T    F I X E N", link: Secrets.NotionShitFixenUrl.Get() }
    static huisNotes := { title: "Huis Notes", link: Secrets.NotionHuisNotesUrl.Get() }
    static workDashboard := { title: "VGZ Dashboard", link: Secrets.NotionWorkDashboardUrl.Get() }
}


Class Notion extends App {
    static __New() => App.Init(
        winTitle := "Notion", 
        ahk_exe := "Notion.exe"
    )
    
    static OpenPage(page) {
        Info("Open Notion " page.title, timeout := 4000)

        ; Check if page is already open
        if WinExist(page.title) {
            WinActivate(page.title)
            WinMaximize(page.title)
            Notion.ScrollToTop(page)
            return
        }
        
        Run("notion:" Trim(page.link, "https://www."))
        WinWaitActive(page.title, "", 10) ; Wait for 10 sec max
        WinMaximize(page.title)
        Notion.ScrollToTop(page)
    }

    static ScrollToTop(page) {
        ; Wait for page to be fully loaded by checking for edit element to be visible
        NotionEl := UIA.ElementFromHandle(page.title " ahk_exe Notion.exe")
        
        titleElement := NotionEl.WaitElementFromPath("VR/4K", timeout := 10000) 
        titleElement ? titleElement.Click() : Info("Notion control not found (timeout)", timeout := 5000)
        
        ; Go top top of page
        Send("^{Home}") 
        ; Scroll down a bit to ensure content is visible
        loop 5 {
            Send("{WheelDown}")
            Sleep(10)
        }
    }
}
