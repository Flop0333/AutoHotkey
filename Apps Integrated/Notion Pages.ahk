; Profile-specific Notion page definitions belong at the application boundary,
; not in the reusable Notion automation class.

#Include ..\Secrets\Secrets Service.ahk

class NotionPages {
    static shitFixen := { title: "S H I T    F I X E N", link: Secrets.NotionShitFixenUrl.Get() }
    static huisNotes := { title: "Huis Notes", link: Secrets.NotionHuisNotesUrl.Get() }
    static workDashboard := { title: "VGZ Dashboard", link: Secrets.NotionWorkDashboardUrl.Get() }
}
