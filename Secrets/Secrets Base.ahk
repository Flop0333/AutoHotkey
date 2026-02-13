; ============================================================================
; === Secrets Base Class =====================================================
; ============================================================================
;
; This file defines the SecretsBase class with secret properties.
; This is used as a template for Secrets.ahk, to prevent runtime errors
; when the actual Secrets.ahk file is missing.
; ============================================================================

#Include Secrets Service.ahk

class SecretsBase {
    static WorkMail := Secret("work email", "Used in key bindings", "")
    static WorkAdminMail := Secret("work admin email", "Used in key bindings", "")
    static PersonalMail := Secret("personal email", "Used in key bindings", "")
    static FamilyMail := Secret("family email", "Used in key bindings", "")
    static TelNumber := Secret("telephone number", "Used in key bindings", "")
    static Address := Secret("address", "Used in key bindings", "")
    static GooglemapsUrl := Secret("Google Maps URL", "Used for quick launching using Age of Efficiency and Macro Board", "")
    static WeatherUrl := Secret("Weather URL", "Used for quick launching using Age of Efficiency and Macro Board", "")
    static FinanceUrl := Secret("Finance URL", "Used for quick launching using Age of Efficiency and Macro Board", "")

    static NotionShitFixenUrl := Secret("Notion SHIT FIXEN URL", "Used to open the SHIT FIXEN page in Notion", "")
    static NotionHuisNotesUrl := Secret("Notion Huis Notes URL", "Used to open the Huis Notes page in Notion", "")
    static NotionWorkDashboardUrl := Secret("Notion Work Dashboard URL", "Used to open the Work Dashboard page in Notion", "")

    static WorkDeviceNames := Secret("Work Device Names", "Used for profiles to identify work devices by computer name", "")
    static WorkBoard := Secret("Work Board", "Link to board", "")
    static WorkVM := Secret("Work Virtual Machine", "Link to work virtual machine", "")
    
    static WorkAI := Secret("Work AI", "Link to work AI", "")
    
    ; Work URLs
    static OFMUrl := Secret("OFM", "SharePoint OFM documentation", "")
    static AFASUrl := Secret("AFAS", "portal", "")
    static DeclaratieUrl := Secret("Declaratie", "declaratie form", "")
    static VerlofUrl := Secret("Verlof", "verlof overview", "")
    static PasswordResetUrl := Secret("Password Reset", "Microsoft password reset portal", "")
    static ZelfAanZetUrl := Secret("Zelf Aan Zet", "Work development portal", "")
    static ICTPortalUrl := Secret("ICT Portal", "Cherwell ICT portal", "")
    static MedewerkersDossierUrl := Secret("Medewerkers Dossier", "Employee dossier in AFAS", "")
    static CherwellUrl := Secret("Cherwell", "Cherwell service management", "")
    
    ; Apollo URLs
    static ApolloPullRequestsUrl := Secret("Apollo Pull Requests", "Azure DevOps Apollo pull requests", "")
    static ApolloPipelineUrl := Secret("Apollo Pipeline", "Azure DevOps Apollo pipeline", "")
    static ApolloOTUrl := Secret("Apollo OT", "Apollo OT environment", "")
    static ApolloATUrl := Secret("Apollo AT", "Apollo AT environment", "")
    static ApolloOTInsightsUrl := Secret("Apollo OT Insights", "Application Insights for Apollo OT", "")
    static ApolloATInsightsUrl := Secret("Apollo AT Insights", "Application Insights for Apollo AT", "")
    static ApolloPRInsightsUrl := Secret("Apollo PR Insights", "Application Insights for Apollo PR", "")
    static ApolloOTSwaggerUrl := Secret("Apollo OT Swagger", "Apollo OT API documentation", "")
    static ApolloATSwaggerUrl := Secret("Apollo AT Swagger", "Apollo AT API documentation", "")
    
    ; Athena URLs
    static APIPullRequestsUrl := Secret("API Pull Requests", "Azure DevOps Athena API pull requests", "")
    static KennisPullRequestsUrl := Secret("Kennis Pull Requests", "Azure DevOps Athena Kennis pull requests", "")
    static CallcenterPullRequestsUrl := Secret("Callcenter Pull Requests", "Azure DevOps Athena Callcenter pull requests", "")
    static KennisOTUrl := Secret("Kennis OT", "Athena Kennis OT environment", "")
    static KennisATUrl := Secret("Kennis AT", "Athena Kennis AT environment", "")
    static CallcenterOTUrl := Secret("Callcenter OT", "Athena Callcenter OT environment", "")
    static CallcenterATUrl := Secret("Callcenter AT", "Athena Callcenter AT environment", "")
    static AthenaPipelineUrl := Secret("Athena Pipeline", "Azure DevOps Athena pipeline", "")
    static AthenaOTInsightsUrl := Secret("Athena OT Insights", "Application Insights for Athena OT", "")
    static AthenaATInsightsUrl := Secret("Athena AT Insights", "Application Insights for Athena AT", "")
}