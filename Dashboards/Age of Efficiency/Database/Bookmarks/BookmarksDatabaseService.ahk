#Include ..\..\..\..\Lib\Core.ahk
#Include Bookmark.ahk
#Include BookmarksState.ahk
#Include ../BaseDatabaseService.ahk

Class BookmarksDatabaseService extends BaseDatabaseService {

  STORAGE_FILE_PATH := Paths.dashboards "\Age of Efficiency\Database\Bookmarks\Bookmarks.json"

  GetBookmarks() {
    result := this.GetItems(Bookmark)
    BookmarksState.SetUniqueId(result.highestId)
    return result.items
  }

  StoreBookmarks() => this.StoreItems(BookmarksState.state)
}
