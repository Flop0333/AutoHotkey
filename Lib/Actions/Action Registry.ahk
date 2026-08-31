#Requires AutoHotkey v2
#Include Action.ahk
#Include Action Context.ahk
#Include Action Result.ahk
#Include Action Log.ahk

/**
 * Authoritative in-memory registry for suite actions.
 * Consumers should invoke actions only through Invoke(), never Execute.Call().
 */
class ActionRegistry {
    /** Process-local definitions; every separately running AHK script has its own registry. */
    static _actions := Map()
    /** Trusted source of the active profile used by policy checks. */
    static _profileProvider := (*) => ""
    /** Injectable prompt keeps confirmation testable and UI-independent. */
    static _confirmationProvider := (message, title, options) => MsgBox(message, title, options)

    /** Adds one definition and rejects duplicate IDs regardless of casing. */
    static Register(definition) {
        if Type(definition) != "Action"
            throw TypeError("ActionRegistry.Register expects an Action")

        if this._actions.Has(definition.Id)
            throw ValueError("Duplicate action id '" definition.Id "' while registering '" definition.Title "'. Existing action: '" this._actions[definition.Id].Title "'")

        this._actions[definition.Id] := definition
        return definition
    }

    /** Atomically registers a batch and rolls it all back when one item fails. */
    static RegisterAll(actions, source := "unknown module") {
        if !(actions is Array)
            throw TypeError("ActionRegistry.RegisterAll expects an Array")

        registeredIds := []
        try {
            for definition in actions {
                this.Register(definition)
                registeredIds.Push(definition.Id)
            }
        } catch as registryError {
            for id in registeredIds
                this._actions.Delete(id)
            throw Error("Action registration failed in " source ": " registryError.Message)
        }
        return actions
    }

    /** Checks whether an ID is registered in this process. */
    static Has(id) => this._actions.Has(this._NormalizeId(id))

    /** Returns a definition or throws when its ID is unknown. */
    static Get(id) {
        id := this._NormalizeId(id)
        if !this._actions.Has(id)
            throw UnsetError("Action not found: " id)
        return this._actions[id]
    }

    /** Returns a definition, or an empty string when its ID is unknown. */
    static TryGet(id) => this._actions.Get(this._NormalizeId(id), "")

    /** Lists definitions with optional profile, availability, category, state, or tag filters. */
    static GetAll(filters := unset) {
        filters := IsSet(filters) ? filters : {}
        results := []
        for id, definition in this._actions
            if this._MatchesFilters(definition, filters)
                results.Push(definition)
        return results
    }

    /** Searches presentation metadata while honoring optional GetAll() filters. */
    static Search(query, filters := unset) {
        query := StrLower(Trim(query))
        results := []
        for definition in this.GetAll(IsSet(filters) ? filters : {}) {
            searchable := definition.Title " " definition.Description " " definition.Category
            for alias in definition.Aliases
                searchable .= " " alias
            for tag in definition.Tags
                searchable .= " " tag
            if query = "" || InStr(StrLower(searchable), query)
                results.Push(definition)
        }
        return results
    }

    /**
     * Conservative discovery surface for remote, voice, or AI consumers.
     * Sensitive/destructive definitions are excluded unless explicitly opted in.
     */
    static GetDiscoverable(context := unset, options := unset) {
        context := IsSet(context) ? context : ActionContext("discovery")
        options := IsSet(options) ? options : {}
        allowSensitive := options.HasOwnProp("allowSensitive") && options.allowSensitive
        allowDestructive := options.HasOwnProp("allowDestructive") && options.allowDestructive
        activeProfile := this._profileProvider.Call()
        results := []

        for id, definition in this._actions {
            if !this.IsEligible(definition, activeProfile) || !this.IsAvailable(definition)
                continue
            if definition.Confirmation.Level = ActionConfirmation.LEVEL_DESTRUCTIVE && !allowDestructive
                continue
            if definition.Confirmation.Level = ActionConfirmation.LEVEL_SENSITIVE && !allowSensitive
                continue
            if !allowSensitive {
                sensitiveTagged := false
                for tag in definition.Tags
                    if StrLower(tag) = "sensitive" {
                        sensitiveTagged := true
                        break
                    }
                if sensitiveTagged
                    continue
            }
            results.Push(definition)
        }
        return results
    }

    /** Enforces every policy, executes once, and always returns an ActionResult. */
    static Invoke(id, argument := unset, context := unset) {
        startedAt := A_TickCount
        id := this._NormalizeId(id)
        context := IsSet(context) ? context : ActionContext()

        if !this._actions.Has(id)
            return this._Complete(ActionResult.ValidationFailed(id, "Unknown action: " id), context)

        definition := this._actions[id]
        activeProfile := this._profileProvider.Call()

        if !this.IsEligible(definition, activeProfile)
            return this._Complete(ActionResult.Unavailable(id, "Action is not available for the current profile"), context)
        if !this.IsAvailable(definition)
            return this._Complete(ActionResult.Unavailable(id), context)

        if definition.Argument.IsRequired && (!IsSet(argument) || argument = "")
            return this._Complete(ActionResult.ValidationFailed(id, definition.Argument.Prompt != "" ? definition.Argument.Prompt : "This action requires an argument"), context)
        if !definition.Argument.AcceptsArgument && IsSet(argument) && argument != ""
            return this._Complete(ActionResult.ValidationFailed(id, "This action does not accept an argument"), context)

        if definition.Confirmation.IsRequired {
            message := definition.Confirmation.Message != "" ? definition.Confirmation.Message : "Run '" definition.Title "'?"
            if this._confirmationProvider.Call(message, "Confirm action", "YesNo Icon!") != "Yes"
                return this._Complete(ActionResult.Cancelled(id), context)
        }

        try {
            value := IsSet(argument) && definition.Argument.AcceptsArgument
                ? definition.Execute.Call(argument)
                : definition.Execute.Call()
            return this._Complete(ActionResult.Success(id, IsSet(value) ? value : "", A_TickCount - startedAt), context)
        } catch as executionError {
            ; Exception messages can contain arguments or secret-backed values.
            diagnostic := executionError.What " | " executionError.File ":" executionError.Line
            return this._Complete(ActionResult.ExecutionFailed(id, "Action '" definition.Title "' failed", diagnostic, A_TickCount - startedAt), context)
        }
    }

    /** Safely evaluates a definition's runtime availability predicate. */
    static IsAvailable(actionOrId) {
        definition := Type(actionOrId) = "Action" ? actionOrId : this.Get(actionOrId)
        try return !!definition.IsAvailable.Call()
        catch
            return false
    }

    /** Applies profile restrictions; restricted actions fail closed without a profile. */
    static IsEligible(actionOrId, profile := "") {
        definition := Type(actionOrId) = "Action" ? actionOrId : this.Get(actionOrId)
        allowedProfiles := definition.Profiles
        if allowedProfiles.Length = 0
            return true
        if profile = ""
            return false

        currentName := profile is String ? profile : profile.displayName
        for allowedProfile in allowedProfiles {
            allowedName := allowedProfile is String ? allowedProfile : allowedProfile.displayName
            if StrLower(allowedName) = StrLower(currentName)
                return true
        }
        return false
    }

    /** Reads toggle state with profile, availability, error, and logging safeguards. */
    static TryGetState(id, context := unset) {
        startedAt := A_TickCount
        id := this._NormalizeId(id)
        context := IsSet(context) ? context : ActionContext("state")

        if !this._actions.Has(id)
            return this._Complete(ActionResult.ValidationFailed(id, "Unknown action: " id), context)

        definition := this._actions[id]
        if !definition.IsToggle
            return this._Complete(ActionResult.ValidationFailed(id, "Action is not state-aware: " id), context)
        if !this.IsEligible(definition, this._profileProvider.Call())
            return this._Complete(ActionResult.Unavailable(id, "Action state is not available for the current profile"), context)
        if !this.IsAvailable(definition)
            return this._Complete(ActionResult.Unavailable(id, "Action state is unavailable"), context)

        try {
            value := definition.GetState.Call()
            return this._Complete(ActionResult.Success(id, value, A_TickCount - startedAt), context)
        } catch as stateError {
            diagnostic := stateError.What " | " stateError.File ":" stateError.Line
            return this._Complete(ActionResult.ExecutionFailed(id, "Could not read state for '" definition.Title "'", diagnostic, A_TickCount - startedAt), context)
        }
    }

    /** Convenience API for trusted callers that prefer an exception to an ActionResult. */
    static GetState(id, context := unset) {
        result := this.TryGetState(id, IsSet(context) ? context : ActionContext("state"))
        if !result.Succeeded
            throw Error(result.message)
        return result.value
    }

    /** Reports consumer IDs missing from the live process registry. */
    static ValidateReferences(ids) {
        errors := []
        for id in ids
            if !this.Has(id)
                errors.Push("Missing action reference: " id)
        return errors
    }

    /** Safe development diagnostics; output contains metadata only. */
    static Diagnose() {
        issues := []
        for id, definition in this._actions {
            if !HasMethod(definition.Execute, "Call")
                issues.Push(id ": execute is not callable")

            for allowedProfile in definition.Profiles
                if !(allowedProfile is String) && !allowedProfile.HasOwnProp("displayName")
                    issues.Push(id ": invalid profile entry")

            if definition.IsToggle {
                try definition.GetState.Call()
                catch
                    issues.Push(id ": state getter failed")
            }

            if definition.Icon != "" && (InStr(definition.Icon, "\\") || InStr(definition.Icon, "/")) && !FileExist(definition.Icon)
                issues.Push(id ": icon file is unavailable")
        }
        return issues
    }

    /** Formats Diagnose() output for a tray dialog or developer message. */
    static FormatDiagnostics() {
        issues := this.Diagnose()
        if issues.Length = 0
            return "Action Registry: " this.Count " actions registered; no diagnostic issues found."

        report := "Action Registry: " this.Count " actions registered; " issues.Length " issue(s):"
        for issue in issues
            report .= "`n- " issue
        return report
    }

    /** Clears definitions, mainly for tests; configured providers remain intact. */
    static Reset() => this._actions.Clear()

    /** Sets the sole authoritative source used for profile eligibility. */
    static SetProfileProvider(provider) {
        if !HasMethod(provider, "Call")
            throw TypeError("ActionRegistry profile provider must be callable")
        this._profileProvider := provider
    }
    /** Injects confirmation UI or a deterministic test double. */
    static SetConfirmationProvider(provider) {
        if !HasMethod(provider, "Call")
            throw TypeError("ActionRegistry confirmation provider must be callable")
        this._confirmationProvider := provider
    }
    /** Number of definitions registered in the current process. */
    static Count {
        get => this._actions.Count
    }

    /** Finalizes results through the bounded, metadata-only action log. */
    static _Complete(result, context) {
        ActionLog.Record(result.actionId, context.consumer, result.status, result.durationMs)
        return result
    }

    /** Shared filter implementation used by listing and search. */
    static _MatchesFilters(definition, filters) {
        if filters.HasOwnProp("profile") && !this.IsEligible(definition, filters.profile)
            return false
        if filters.HasOwnProp("available") && filters.available && !this.IsAvailable(definition)
            return false
        if filters.HasOwnProp("category") && StrLower(definition.Category) != StrLower(filters.category)
            return false
        if filters.HasOwnProp("stateful") && filters.stateful != definition.IsToggle
            return false
        if filters.HasOwnProp("tag") {
            found := false
            for tag in definition.Tags
                if StrLower(tag) = StrLower(filters.tag) {
                    found := true
                    break
                }
            if !found
                return false
        }
        return true
    }

    /** Makes lookup case-insensitive and rejects empty IDs at the boundary. */
    static _NormalizeId(id) {
        id := StrLower(Trim(id))
        if id = ""
            throw ValueError("Action id cannot be empty")
        return id
    }
}
