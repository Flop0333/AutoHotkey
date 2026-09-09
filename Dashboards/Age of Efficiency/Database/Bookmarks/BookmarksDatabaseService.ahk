#Include Bookmark.ahk
#Include ../BaseDatabaseService.ahk
#Include ..\..\..\..\Lib\Core\Paths.ahk

Class BookmarksDatabaseService extends BaseDatabaseService {

  STORAGE_FILE_PATH := Paths.dashboards "\Age of Efficiency\Database\Bookmarks\Bookmarks.json"

  Load() => this.GetItems(Bookmark)

  Store(items) => this.StoreItems(items)
}
