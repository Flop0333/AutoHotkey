#Requires AutoHotkey v2
#Include Action Ids.ahk
#Include Action Argument.ahk
#Include Action Confirmation.ahk

/**
 * Immutable shared definition for one executable suite action.
 * Consumer-specific bindings and layout do not belong in this model.
 *
 * Example:
 *   Action("timer.start", "Start Timer", StartTimer, {
 *       category: "Productivity",
 *       argument: ActionArgument.Required("Minutes")
 *   })
 */
class Action {
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

    Id {
        get => this._id
    }
    Title {
        get => this._title
    }
    Execute {
        get => this._execute
    }
    Description {
        get => this._description
    }
    Category {
        get => this._category
    }
    Icon {
        get => this._icon
    }
    Aliases {
        get => this._aliases.Clone()
    }
    Profiles {
        get => this._profiles.Clone()
    }
    Tags {
        get => this._tags.Clone()
    }
    Argument {
        get => this._argument
    }
    IsAvailable {
        get => this._isAvailable
    }
    GetState {
        get => this._getState
    }
    Confirmation {
        get => this._confirmation
    }
    IsToggle {
        get => this._getState != ""
    }

    _Option(options, name, defaultValue) => options.HasOwnProp(name) ? options.%name% : defaultValue

    _CloneList(value, fieldName) {
        if value is Array
            return value.Clone()
        if value = ""
            return []
        throw TypeError("Action '" this._id "' " fieldName " value must be an Array")
    }
}
