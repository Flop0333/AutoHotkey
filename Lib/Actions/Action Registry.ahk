#Requires AutoHotkey v2
#Include Action.ahk
#Include Action Context.ahk
#Include Action Result.ahk

/**
 * Authoritative in-memory registry for suite actions.
 * Consumers should invoke actions only through Invoke(), never Execute.Call().
 */
class ActionRegistry {
    static _actions := Map()
    static _profileProvider := (*) => ""

    static Register(definition) {
        if Type(definition) != "Action"
            throw TypeError("ActionRegistry.Register expects an Action")

        if this._actions.Has(definition.Id)
            throw ValueError("Duplicate action id '" definition.Id "' while registering '" definition.Title "'. Existing action: '" this._actions[definition.Id].Title "'")

        this._actions[definition.Id] := definition
        return definition
    }

    static RegisterIfMissing(definition) => this.Has(definition.Id) ? this.Get(definition.Id) : this.Register(definition)

    static RegisterAll(actions) {
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
            throw registryError
        }
        return actions
    }

    static Has(id) => this._actions.Has(this._NormalizeId(id))

    static Get(id) {
        id := this._NormalizeId(id)
        if !this._actions.Has(id)
            throw UnsetError("Action not found: " id)
        return this._actions[id]
    }

    static TryGet(id) => this._actions.Get(this._NormalizeId(id), "")

    static GetAll(filters := unset) {
        filters := IsSet(filters) ? filters : {}
        results := []
        for id, definition in this._actions
            if this._MatchesFilters(definition, filters)
                results.Push(definition)
        return results
    }

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

    static Invoke(id, argument := unset, context := unset) {
        startedAt := A_TickCount
        id := this._NormalizeId(id)
        context := IsSet(context) ? context : ActionContext()

        if !this._actions.Has(id)
            return ActionResult.ValidationFailed(id, "Unknown action: " id)

        definition := this._actions[id]
        activeProfile := context.profile != "" ? context.profile : this._profileProvider.Call()

        if !this.IsEligible(definition, activeProfile)
            return ActionResult.Unavailable(id, "Action is not available for the current profile")
        if !this.IsAvailable(definition)
            return ActionResult.Unavailable(id)

        if definition.Argument.IsRequired && (!IsSet(argument) || argument = "")
            return ActionResult.ValidationFailed(id, definition.Argument.Prompt != "" ? definition.Argument.Prompt : "This action requires an argument")
        if !definition.Argument.AcceptsArgument && IsSet(argument) && argument != ""
            return ActionResult.ValidationFailed(id, "This action does not accept an argument")

        if definition.Confirmation.IsRequired && !context.confirmationGranted {
            message := definition.Confirmation.Message != "" ? definition.Confirmation.Message : "Run '" definition.Title "'?"
            if MsgBox(message, "Confirm action", "YesNo Icon!") != "Yes"
                return ActionResult.Cancelled(id)
        }

        try {
            value := IsSet(argument) && definition.Argument.AcceptsArgument
                ? definition.Execute.Call(argument)
                : definition.Execute.Call()
            return ActionResult.Success(id, IsSet(value) ? value : "", A_TickCount - startedAt)
        } catch as executionError {
            diagnostic := executionError.Message " | " executionError.What " | " executionError.File ":" executionError.Line
            return ActionResult.ExecutionFailed(id, "Action '" definition.Title "' failed", diagnostic, A_TickCount - startedAt)
        }
    }

    static IsAvailable(actionOrId) {
        definition := Type(actionOrId) = "Action" ? actionOrId : this.Get(actionOrId)
        try return !!definition.IsAvailable.Call()
        catch
            return false
    }

    static IsEligible(actionOrId, profile := "") {
        definition := Type(actionOrId) = "Action" ? actionOrId : this.Get(actionOrId)
        allowedProfiles := definition.Profiles
        if allowedProfiles.Length = 0 || profile = ""
            return true

        currentName := profile is String ? profile : profile.displayName
        for allowedProfile in allowedProfiles {
            allowedName := allowedProfile is String ? allowedProfile : allowedProfile.displayName
            if StrLower(allowedName) = StrLower(currentName)
                return true
        }
        return false
    }

    static GetState(id) {
        definition := this.Get(id)
        if !definition.IsToggle
            throw ValueError("Action is not state-aware: " definition.Id)
        return definition.GetState.Call()
    }

    static ValidateReferences(ids) {
        errors := []
        for id in ids
            if !this.Has(id)
                errors.Push("Missing action reference: " id)
        return errors
    }

    static Reset() => this._actions.Clear()

    static SetProfileProvider(provider) {
        if !HasMethod(provider, "Call")
            throw TypeError("ActionRegistry profile provider must be callable")
        this._profileProvider := provider
    }
    static Count {
        get => this._actions.Count
    }

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

    static _NormalizeId(id) {
        id := StrLower(Trim(id))
        if id = ""
            throw ValueError("Action id cannot be empty")
        return id
    }
}
