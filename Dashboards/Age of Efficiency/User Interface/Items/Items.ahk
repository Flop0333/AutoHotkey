#Include ../../Database/Bookmarks/BookmarksState.ahk
#Include ../../Database/Internet Search/SearchEnginesState.ahk
#Include ../../Database/Apps/AppsState.ahk
#Include ../../Input Handler/Command Executor.ahk
#Include ..\..\..\..\Secrets\Secrets Service.ahk

Global TAB_OPTIONS := {Bookmarks: "Bookmarks", Apps: "Apps", Search: "Search"}

ClickItem(WebView, item, currentTabTab) {
	aoeWindow.Minimize() ; Hide first so a bookmark does not try to run in Neutron Gui
	item := JSON.ToObject(item)

	; Check if the item requires an argument
	if currentTabTab = TAB_OPTIONS.Search || (currentTabTab = TAB_OPTIONS.Apps && item.argumentRequired = 1)
		CommandInput().WaitForArgumentAndExecute(item.command)
	else 
		CommandExecutor.Execute(item.command)
}

DeleteItemItem(WebView, itemTitle, currentTabTab) {
	switch currentTabTab {
		case TAB_OPTIONS.Bookmarks: BookmarksState.Delete(itemTitle)
		case TAB_OPTIONS.Apps: 		AppsState.Delete(itemTitle)
		case TAB_OPTIONS.Search: 	SearchEnginesState.Delete(itemTitle)
	}
}

GetItemByTitle(WebView, itemTitle, currentTabTab) {
	switch currentTabTab {
		case TAB_OPTIONS.Bookmarks: 	item := BookmarksState.GetByCommandOrTitle(itemTitle)
		case TAB_OPTIONS.Apps: 		item := AppsState.GetByCommandOrTitle(itemTitle)
		case TAB_OPTIONS.Search: 	item := SearchEnginesState.GetByCommandOrTitle(itemTitle)
	}
	
	; For secret bookmarks, add secret details and set url to actual value
	if currentTabTab = TAB_OPTIONS.Bookmarks && item.isSecret {
		item.secretPropertyName := item.url
		item.secretName := Secrets.%item.url%.name
		item.secretDescription := Secrets.%item.url%.description
		item.url := Secrets.%item.url%.GetOrSet()
	}
	
	return json.Dump(item)
}

GetItemIcons(WebView) {
	icons := []
	Loop Files, "Library\Icons\Custom Item\*.png*"
		icons.Push(SubStr(A_LoopFileName, 1, -4)) ; remove .png)
	return json.Dump(icons)
}

GetUrlFromClipboard(WebView) {
	resultUrl := ""
	resultTitle := ""

	url := RegExMatch(A_Clipboard, "^https?://|^ftp://|^file://")
	if url = 1 { ; Check if clipboard is an url
		resultUrl := A_Clipboard
		splitted := StrSplit(A_Clipboard, ".")
		resultTitle := splitted[2]
	}
	return json.Dump({url: resultUrl, title: resultTitle})
}
 

SubmitForm(WebView, Form, updateMode, currentTabTab) => SetTimer((*) => FormSubmitEvent(WebView, Form, updateMode, currentTabTab), -1)
FormSubmitEvent(WebView, Form, updateMode, currentTabTab) {
	formMap := JSON.parse(Form)

	; Map tab to class and state
	tabItemMap := Map(
		"Bookmarks", {class: Bookmark, state: BookmarksState},
		"Apps", {class: CustomApp, state: AppsState},
		"Search", {class: SearchEngine, state: SearchEnginesState}
	)
	; Get the correct class and state based on the current tab
	tabDataset := tabItemMap[currentTabTab]

	; Create new item instance of the correct class
	datasetClassObject := tabDataset.class()

	; Handle creating a new bookmark Secret 
	if currentTabTab = "Bookmarks" && formMap["isSecret"] = true {
		newSecret := Secret(formMap["secretName"], formMap["secretDescription"], formMap["url"], formMap["secretPropertyName"])
		if updateMode
			SecretsFileManager.UpdateExistingSecret(newSecret)
		else
			SecretsFileManager.CreateNewSecret(newSecret)
		
		; Set the property name to the bookmark url for later retrieval of the secret
		formMap["url"] := formMap["secretPropertyName"]
	}

	; Populate item properties from formMap, only if the property exists on the class
	for key, value in formMap
		if datasetClassObject.HasOwnProp(key)
			datasetClassObject.%key% := value
			
	updateMode ? tabDataset.state.Update(datasetClassObject) : tabDataset.state.Create(datasetClassObject)
}