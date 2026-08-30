; ============================================================================
; === Command Executor =======================================================
; ============================================================================
;
; [FEATURES]
;   - Executes commands based on user input
;   - Supports bookmarks, internet searches, and app methods using their states
;   - Handles commands with and without arguments
; ============================================================================

#Include ../Database/Apps/AppsState.ahk
#Include ../Database/Bookmarks/BookmarksState.ahk
#Include ../Database/Internet Search/SearchEnginesState.ahk
#Include Command Methods.ahk

Class CommandExecutor {
    static _command := String
    static _argument := String

    static Execute(input) {
       if input = ""
            return false

        this._command := this._ExtractCommand(input)
        this._argument := this._ExtractArgument(input)

        return this._TryBookmark() || this._TryMethod() || this._TryInternetSearch() 
    }
    
    static _TryBookmark() {
        ; An argument selects the matching search engine instead of a same-name bookmark.
        if this._argument != ""
            return false

        if !(bookmark := BookmarksState.GetByCommandOrTitle(this._command))
            return false

        ; If bookmark is secret, get actual url from Secrets
        url := bookmark.isSecret ? Secrets.%bookmark.url%.GetOrSet() : bookmark.url
        
        Browser.OpenUrlUnderMouse(url)
        return true
    }
    
    static _TryMethod() {
        if !(app := AppsState.GetByCommandOrTitle(this._command))
            return false

        if !ActionRegistry.Has(app.actionId) {
            Info("Action is not registered: " app.actionId)
            return true
        }

        action := ActionRegistry.Get(app.actionId)
        argument := this._argument
        if action.Argument.IsRequired && argument = ""
            argument := CommandInput().WaitForInput()

        if action.Argument.IsRequired && argument = ""
            return true ; User cancelled input.

        context := ActionContext("age-of-efficiency", ProfileManager.current)
        result := argument != ""
            ? ActionRegistry.Invoke(action.Id, argument, context)
            : ActionRegistry.Invoke(action.Id, unset, context)

        if result.status != ActionResult.STATUS_SUCCESS && result.status != ActionResult.STATUS_CANCELLED
            Info(result.message)

        return true
    }

    static _TryInternetSearch() {
        if !(searchEngine := SearchEnginesState.GetByCommandOrTitle(this._command))
            return false

        argument := this._argument || CommandInput().WaitForInput()

        InternetSearcher(this._command).Search(argument)
        return true
    }

    static _ExtractCommand(command) => StrSplit(command, A_Space)[1]
    
    static _ExtractArgument(command) {
        try argument := StrSplit(command, A_Space,,2)[2]
        return IsSet(argument) ? argument : ""
    }
}
