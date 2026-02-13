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
        if !(bookmark := BookmarksState.GetByCommandOrTitle(this._command))
            return false

        ; If bookmark is secret, get actual url from Secrets
        if bookmark.isSecret
            bookmark.url := Secrets.%bookmark.url%.GetOrSet()
        
        Browser.OpenUrlUnderMouse(bookmark.url)
        return true
    }
    
    static _TryMethod() {
        if !(app := AppsState.GetByCommandOrTitle(this._command))
            return false

        if app.argumentRequired {
            argument := this._argument || CommandInput().WaitForInput()
            if argument != "" ; User has cancelled input
                %app.action%(argument)
        } else
            %app.action%()

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