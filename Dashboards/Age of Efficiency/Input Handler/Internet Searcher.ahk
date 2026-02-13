; ============================================================================
; === Internet Searcher ======================================================
; ============================================================================
;
; [FEATURES]
;   - Facilitates internet searches using various search engines
;   - Detects the browser under the mouse cursor to use for the search
;   - Supports custom search engines via command, title, or URL
; ============================================================================

#Include ..\..\..\Lib\Apps\Browser.ahk
#Include ..\..\..\Lib\Helpers\Number Convertor.ahk
#Include ..\..\..\Lib\Extensions\String.ahk
#Include ../Database/Internet Search/SearchEngine.ahk
#Include ../Database/Internet Search/SearchEnginesState.ahk

Class InternetSearcher {

    _DEFAULT_SEARCH_ENGINE := SearchEngine(0, "Google", "www.google.com/search?q=", "G")

    _selectedSearchEngine := this._DEFAULT_SEARCH_ENGINE
    
	__New(searchEngine_Title_Command_Or_SearchableUrl := this._DEFAULT_SEARCH_ENGINE) {
		this._SetSearchEngine(searchEngine_Title_Command_Or_SearchableUrl)
	}
    
    Search(input) {
        query := this._ConvertQuery(input)
		Browser.OpenUrlUnderMouse(this._selectedSearchEngine.url query)
    }

	_SetSearchEngine(newEngine) {
		searchEngine := SearchEnginesState.GetByCommandOrTitle(newEngine)

		if searchEngine != ""
			this._selectedSearchEngine := searchEngine
		
		else if InStr(newEngine.url, "www.")
            this._selectedSearchEngine.url := newEngine.url
		
		else
        	MsgBox("Accepted parameters: `n-Search engine `n-Search engines name `n-Search engines command `n-Searchable url","16")
	}

	_ConvertQuery(query) {
		SpecialCharacters := '%$&+,/:;=?@ "<>#{}|\^~[]``'.Split()
		for key, value in SpecialCharacters 
			query := query.Replace(value, "%" NumberConverter.DecToHex(Ord(value), false))

		return query
	}
}