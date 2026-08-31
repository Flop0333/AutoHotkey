; ============================================================================
; === Secrets Catalog ========================================================
; ============================================================================
;
; Tracked definitions for every supported secret. Personal values live in the
; local, git-ignored My Secrets.json file and are keyed by these identifiers.
; ============================================================================

SecretsCatalog := Map(
    "WorkMail", Secret("work email", "Used in key bindings"),
    "SecondWorkMail", Secret("second work email", "Used in key bindings"),
    "WorkAdminMail", Secret("work admin email", "Used in key bindings"),
    "PersonalMail", Secret("personal email", "Used in key bindings"),
    "FamilyMail", Secret("family email", "Used in key bindings"),
    "TelNumber", Secret("telephone number", "Used in key bindings"),
    "Address", Secret("address", "Used in key bindings"),
    "GooglemapsUrl", Secret("Google Maps URL", "Used for quick launching using Age of Efficiency and Macro Board"),
    "WeatherUrl", Secret("Weather URL", "Used for quick launching using Age of Efficiency and Macro Board"),
    "FinanceUrl", Secret("Finance URL", "Used for quick launching using Age of Efficiency and Macro Board"),
    "NotionShitFixenUrl", Secret("Notion SHIT FIXEN URL", "Used to open the SHIT FIXEN page in Notion"),
    "NotionHuisNotesUrl", Secret("Notion Huis Notes URL", "Used to open the Huis Notes page in Notion"),
    "NotionWorkDashboardUrl", Secret("Notion Work Dashboard URL", "Used to open the Work Dashboard page in Notion"),
    "WorkDeviceNames", Secret("Work Device Names", "Used for profiles to identify work devices by computer name"),
    "WorkBoard", Secret("Work Board", "Link to board"),
    "WorkVM", Secret("Work Virtual Machine", "Link to work virtual machine"),
    "ApolloPullRequest", Secret("Apollo Pull Requests", "Link to Apollo pull requests"),
    "AthenaPullRequest", Secret("Athena Pull Requests", "Link to Athena pull requests"),
    "WorkAI", Secret("Work AI", "Link to work AI"),
    "OFMUrl", Secret("OFM", "SharePoint OFM documentation"),
    "AFASUrl", Secret("AFAS", "portal"),
    "DeclaratieUrl", Secret("Declaratie", "declaratie form"),
    "VerlofUrl", Secret("Verlof", "verlof overview"),
    "PasswordResetUrl", Secret("Password Reset", "Microsoft password reset portal"),
    "ZelfAanZetUrl", Secret("Zelf Aan Zet", "Work development portal"),
    "ICTPortalUrl", Secret("ICT Portal", "Cherwell ICT portal"),
    "MedewerkersDossierUrl", Secret("Medewerkers Dossier", "Employee dossier in AFAS"),
    "CherwellUrl", Secret("Cherwell", "Cherwell service management"),
    "ApolloPullRequestsUrl", Secret("Apollo Pull Requests", "Azure DevOps Apollo pull requests"),
    "ApolloPipelineUrl", Secret("Apollo Pipeline", "Azure DevOps Apollo pipeline"),
    "ApolloOTUrl", Secret("Apollo OT", "Apollo OT environment"),
    "ApolloATUrl", Secret("Apollo AT", "Apollo AT environment"),
    "ApolloOTInsightsUrl", Secret("Apollo OT Insights", "Application Insights for Apollo OT"),
    "ApolloATInsightsUrl", Secret("Apollo AT Insights", "Application Insights for Apollo AT"),
    "ApolloPRInsightsUrl", Secret("Apollo PR Insights", "Application Insights for Apollo PR"),
    "ApolloOTSwaggerUrl", Secret("Apollo OT Swagger", "Apollo OT API documentation"),
    "ApolloATSwaggerUrl", Secret("Apollo AT Swagger", "Apollo AT API documentation"),
    "APIPullRequestsUrl", Secret("API Pull Requests", "Azure DevOps Athena API pull requests"),
    "KennisPullRequestsUrl", Secret("Kennis Pull Requests", "Azure DevOps Athena Kennis pull requests"),
    "CallcenterPullRequestsUrl", Secret("Callcenter Pull Requests", "Azure DevOps Athena Callcenter pull requests"),
    "KennisOTUrl", Secret("Kennis OT", "Athena Kennis OT environment"),
    "KennisATUrl", Secret("Kennis AT", "Athena Kennis AT environment"),
    "CallcenterOTUrl", Secret("Callcenter OT", "Athena Callcenter OT environment"),
    "CallcenterATUrl", Secret("Callcenter AT", "Athena Callcenter AT environment"),
    "AthenaPipelineUrl", Secret("Athena Pipeline", "Azure DevOps Athena pipeline"),
    "AthenaOTInsightsUrl", Secret("Athena OT Insights", "Application Insights for Athena OT"),
    "AthenaATInsightsUrl", Secret("Athena AT Insights", "Application Insights for Athena AT")
)
