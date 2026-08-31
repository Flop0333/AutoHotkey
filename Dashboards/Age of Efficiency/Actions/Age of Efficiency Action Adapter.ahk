#Requires AutoHotkey v2

/** Keeps command aliases/presentation in JSON while enforcing registry eligibility. */
class AgeOfEfficiencyActionAdapter {
    static IsEligible(app) {
        if app.actionId = "" || !ActionRegistry.Has(app.actionId)
            return false
        definition := ActionRegistry.Get(app.actionId)
        return ActionRegistry.IsEligible(definition, ProfileManager.current)
            && ActionRegistry.IsAvailable(definition)
    }

    static GetEligible(appRecords) {
        eligible := []
        for appRecord in appRecords
            if this.IsEligible(appRecord)
                eligible.Push(appRecord)
        return eligible
    }

    /** Minimal command-launcher view used by previews and future consumers. */
    static ToCommandPreview(app) {
        if !this.IsEligible(app)
            return ""
        definition := ActionRegistry.Get(app.actionId)
        return {
            actionId: definition.Id,
            command: app.command,
            title: app.title != "" ? app.title : definition.Title,
            argumentRequired: definition.Argument.IsRequired ? 1 : 0,
            argument: app.argument != "" ? app.argument : definition.Argument.Prompt
        }
    }
}
