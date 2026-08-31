#Requires AutoHotkey v2
#Include Action Ids.ahk
#Include Action Argument.ahk
#Include Action Confirmation.ahk

/**
 * Read-only-by-convention shared definition for one executable suite action.
 * Consumer-specific bindings and layout do not belong in this model.
 *
 * Example:
 *   Action(ActionIds.Productivity.TimerStart, "Start Timer", StartTimer, {
 *       category: "Productivity",
 *       argument: ActionArgument.Required("Minutes")
 *   })
 */
class Action {
    /** Validates and freezes the action contract supplied by a definition factory. */
    __New(id, title, execute, options := unset) {
        id := StrLower(Trim(id))
        title := Trim(title)

        if !RegExMatch(id, "^[a-z0-9]+(?:[.-][a-z0-9]+)*$")
            throw ValueError("Invalid action id: " id)
        if title = ""
            throw ValueError("Action '" id "' requires a title")
        if !HasMethod(execute, "Call")
            throw TypeError("Action '" id "' execute value must be callable")

        options := IsSet(options) ? options : {}
        this._id := id
        this._title := title
        this._execute := execute
        this._description := this._Option(options, "description", "")
        this._category := this._Option(options, "category", "")
        this._icon := this._Option(options, "icon", "")
        this._aliases := this._CloneList(this._Option(options, "aliases", []), "aliases")
        this._profiles := this._CloneList(this._Option(options, "profiles", []), "profiles")
        this._tags := this._CloneList(this._Option(options, "tags", []), "tags")
        this._argument := this._Option(options, "argument", ActionArgument.None())
        this._isAvailable := this._Option(options, "isAvailable", (*) => true)
        this._getState := this._Option(options, "getState", "")
        this._confirmation := this._Option(options, "confirmation", ActionConfirmation.Normal())

        if !(this._argument is ActionArgument)
            throw TypeError("Action '" id "' argument must be an ActionArgument")
        if !HasMethod(this._isAvailable, "Call")
            throw TypeError("Action '" id "' isAvailable value must be callable")
        if this._getState != "" && !HasMethod(this._getState, "Call")
            throw TypeError("Action '" id "' getState value must be callable")
        if !(this._confirmation is ActionConfirmation)
            throw TypeError("Action '" id "' confirmation must be an ActionConfirmation")
    }

    /** Stable machine-facing identifier; consumers should use the matching ActionIds constant. */
    Id {
        get => this._id
    }
    /** Human-facing name used by dashboards, menus, and diagnostics. */
    Title {
        get => this._title
    }
    /** Callable implementation; invoke it through ActionRegistry, never directly. */
    Execute {
        get => this._execute
    }
    /** Optional longer explanation for discovery UIs and tooltips. */
    Description {
        get => this._description
    }
    /** Optional presentation grouping used by search and filters. */
    Category {
        get => this._category
    }
    /** Optional consumer-neutral icon name or path. */
    Icon {
        get => this._icon
    }
    /** Alternative search terms; a clone prevents callers mutating the definition. */
    Aliases {
        get => this._aliases.Clone()
    }
    /** Profiles allowed to use this action; an empty list means all profiles. */
    Profiles {
        get => this._profiles.Clone()
    }
    /** Search and policy labels such as "sensitive". */
    Tags {
        get => this._tags.Clone()
    }
    /** Describes whether Invoke() accepts or requires one argument. */
    Argument {
        get => this._argument
    }
    /** Runtime predicate for dependencies such as a running application. */
    IsAvailable {
        get => this._isAvailable
    }
    /** Optional state reader for toggle-style actions. */
    GetState {
        get => this._getState
    }
    /** Central confirmation policy applied before execution. */
    Confirmation {
        get => this._confirmation
    }
    /** An action is state-aware when it supplies a state reader. */
    IsToggle {
        get => this._getState != ""
    }

    /** Reads an optional named field without requiring every caller to build a full options object. */
    _Option(options, name, defaultValue) => options.HasOwnProp(name) ? options.%name% : defaultValue

    /** Defensively copies array metadata so an Action stays read-only by convention. */
    _CloneList(value, fieldName) {
        if value is Array
            return value.Clone()
        if value = ""
            return []
        throw TypeError("Action '" this._id "' " fieldName " value must be an Array")
    }
}
