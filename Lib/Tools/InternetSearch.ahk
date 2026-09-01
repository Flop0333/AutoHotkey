; ============================================================================
; === Internet Search Tool ===================================================
; ============================================================================
;
; [EXAMPLE]
;   InternetSearch("Google").TriggerSearch() ; insert search
;   InternetSearch("Youtube").FeedQuery("boeie")
;
;	note: this class works, but could use an update
; ============================================================================

#Include ..\Helpers\Number Convertor.ahk
#Include User Input.ahk
#Include ..\Extensions\String.ahk
#Include ..\Helpers\ClipSend.ahk
#Include ..\Apps\Browser.ahk

class InternetSearch extends UserInput {

	__New(searchEngine) {
		global currentSearchEngine := searchEngine
		super.__New()
		this.SelectedSearchEngine := this.AvailableSearchEngines[searchEngine]
	}

	FeedQuery(input) {
		restOfLink := this._SanitizeQuery(input)
		Run(this.SelectedSearchEngine restOfLink)
	}

	FeedQueryInSameTab(input) {
		restOfLink := this._SanitizeQuery(input)
		InternetSearch.FindTabAndRunQueryInTab(restOfLink, this.SelectedSearchEngine)
	}

	FeedQueryDashesInSameTab(input) {
		restOfLink := this._SanitizeQueryDashes(input)
		InternetSearch.FindTabAndRunQueryInTab(restOfLink, this.SelectedSearchEngine)
	}

	static FindTabAndRunQueryInTab(restOfLink, selectedSearchEngine) {
		; if Brave.FindTab(currentSearchEngine) { ; search engine name should be somewhere included in the tab name
		; 	Send("!d")	
		; 	ClipSend(selectedSearchEngine restOfLink)
		; 	Send("{Enter}")
		; } else {
		; 	Run(selectedSearchEngine restOfLink)
		; }
	}

	DynamicallyReselectEngine(input) {
		for key, value in this.SearchEngineNicknames {
			if input.RegExMatch("^" key " ") {
				this.SelectedSearchEngine := value
				input := input[3, -1]
				break
			}
		}
		return input
	}

	TriggerSearch() {
		if !input := super.WaitForInput() {
			return false
		}
		query := this.DynamicallyReselectEngine(input)
		this.FeedQuery(query)
	}

	AvailableSearchEngines := Map(
		"Google",  			"https://www.google.com/search?q=",
		"Youtube", 			"https://www.youtube.com/results?search_query=",
		"AutoHotkey", 		"https://www.autohotkey.com/docs/v2/",
		"Flixer",   		"https://theflixer.tv/search/",
		"Spotify Edge",   	Links.spotify "search/",
		"Marktplaats",   	"https://www.marktplaats.nl/q/",
		"Maps",   			"https://www.google.com/maps/dir/home/",
	)

	SearchEngineNicknames := Map(
		"g", 	this.AvailableSearchEngines["Google"],
		"y",  	this.AvailableSearchEngines["Youtube"],
		"ahk",  this.AvailableSearchEngines["AutoHotkey"],
		"f",  	this.AvailableSearchEngines["Flixer"],
		"s",  	this.AvailableSearchEngines["Spotify Edge"],
		"mp",  	this.AvailableSearchEngines["Marktplaats"],
		"maps",	this.AvailableSearchEngines["Maps"],
	)

	_SanitizeQuery(query) {
		SpecialCharacters := '%$&+,/:;=?@ "<>#{}|\^~[]``'.Split()
		for key, value in SpecialCharacters {
			query := query.Replace(value, "%" NumberConverter.DecToHex(Ord(value), false))
		}
		return query
	}

	_SanitizeQueryDashes(query) {
		SpecialCharacters := '%$&+,/:;=?@ "<>#{}|\^~[]``'.Split()
		for key, value in SpecialCharacters {
			query := query.Replace(value, "-")
		}
		return query
	}
}
