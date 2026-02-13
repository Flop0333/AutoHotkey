#Include ..\..\..\Lib\Core.ahk
#Include ..\..\..\Lib\Core\WebView.ahk
#Include Items\Items.ahk	

Class UserInterface extends WebViewToo {

	static SHOW_OPTIONS := Format("y{} w{} h{}", 20, 1000, A_ScreenHeight*0.75)
	static WIN_TITLE := "Age of Efficiency"

	__New() {
		super.__new()
		this.SetVirtualHostNameToFolderMapping("app.local", USER_INTERFACE_PATH, 0) ; block cors error, allow loading local files
		this.Load("http://app.local/index.html")

		this.AddCallbackToScript("ClickItem", ClickItem)
		this.AddCallbackToScript("SubmitForm", SubmitForm)
		this.AddCallbackToScript("DeleteItem", DeleteItemItem)
		this.AddCallbackToScript("GetItemByTitle", GetItemByTitle)
		this.AddCallbackToScript("GetItemIcons", GetItemIcons)
		this.AddCallbackToScript("GetUrlFromClipboard", GetUrlFromClipboard)
		
		this.AddCallbackToScript("GetBookmarksState", 		(WebView) => json.Dump(BookmarksState.state))
		this.AddCallbackToScript("GetBookmarksCategories",	(WebView) => json.Dump(BookmarksState.GetCategories()))
		this.AddCallbackToScript("GetSearchState", 			(WebView) => json.Dump(SearchEnginesState.state))
		this.AddCallbackToScript("GetSearchCategories", 	(WebView) => json.Dump(SearchEnginesState.GetCategories()))
		this.AddCallbackToScript("GetAppsState", 			(WebView) => json.Dump(AppsState.state.allApps))
		this.AddCallbackToScript("GetAppsCategories", 		(WebView) => json.Dump(AppsState.GetCategories()))
		
		this.AddCallbackToScript("ClearBrowsingData", 		(WebView) => this.Profile.ClearBrowsingDataAll(WebView2.Handler(Handler.Bind(this))))
		Handler(hresult) {
		}

		; this.OpenDevToolsWindow()
	}

	Show() => super.Show(UserInterface.SHOW_OPTIONS, UserInterface.WIN_TITLE)
}