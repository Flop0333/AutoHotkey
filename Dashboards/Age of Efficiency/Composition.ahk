; Composition root for the command launcher's persistent state.
; State classes depend only on the repository contract (Load/Store), while this
; executable boundary selects the JSON-file implementations.

#Include ..\..\Lib\Core\OnError.ahk
#Include Database\Apps\AppsState.ahk
#Include Database\Apps\AppsDatabaseService.ahk
#Include Database\Bookmarks\BookmarksState.ahk
#Include Database\Bookmarks\BookmarksDatabaseService.ahk
#Include Database\Internet Search\SearchEnginesState.ahk
#Include Database\Internet Search\SearchEnginesDatabaseService.ahk

InitializeAgeOfEfficiencyState() {
    AppsState.Initialize(AppsDatabaseService(), LogAndNotifyInfo)
    BookmarksState.Initialize(BookmarksDatabaseService(), LogAndNotifyInfo)
    SearchEnginesState.Initialize(SearchEnginesDatabaseService(), LogAndNotifyInfo)
}
