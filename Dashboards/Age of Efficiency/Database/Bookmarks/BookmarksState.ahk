#Include BookmarksDatabaseService.ahk
#Include ../BaseState.ahk

Class BookmarksState extends BaseState {

  static __New() => this.state := BookmarksDatabaseService().GetBookmarks()

  static Store() => BookmarksDatabaseService().StoreBookmarks()
}