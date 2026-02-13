class AhkDataService {
  
  static getItemsByTab(selectedNavigationbar = Navigationbar.getActiveTab()) {
    const ahkItemsByTabMap = new Map([
      [TAB_OPTIONS.Bookmarks, () => JSON.parse(ahk.sync.GetBookmarksState())],
      [TAB_OPTIONS.Apps, () => JSON.parse(ahk.sync.GetAppsState())],
      [TAB_OPTIONS.Search, () => JSON.parse(ahk.sync.GetSearchState())]
    ]);

    return ahkItemsByTabMap.get(selectedNavigationbar)();
  }

  static getAllItems() {
    return [
      ...AhkDataService.getItemsByTab(TAB_OPTIONS.Bookmarks),
      ...AhkDataService.getItemsByTab(TAB_OPTIONS.Apps),
      ...AhkDataService.getItemsByTab(TAB_OPTIONS.Search)
    ];
  }

  static getAhkCategories() {
    const ahkCategoriesByTabMap = new Map([
      [TAB_OPTIONS.Bookmarks, () => JSON.parse(ahk.sync.GetBookmarksCategories())],
      [TAB_OPTIONS.Apps, () => JSON.parse(ahk.sync.GetAppsCategories())],
      [TAB_OPTIONS.Search, () => JSON.parse(ahk.sync.GetSearchCategories())]
    ]);

    return ahkCategoriesByTabMap.get(Navigationbar.getActiveTab())();
  }
  
  static getItemIcons = () => JSON.parse(ahk.sync.GetItemIcons());
  
  static clickItem = (item) => ahk.ClickItem(JSON.stringify(item), Navigationbar.getActiveTab());
  
  static deleteItem = (itemTitle) => ahk.DeleteItem(itemTitle, Navigationbar.getActiveTab());
  
  static getItemByTitle = (itemTitle) => JSON.parse(ahk.sync.GetItemByTitle(itemTitle, Navigationbar.getActiveTab()));
  
  static getUrlFromClipboard = () => JSON.parse(ahk.sync.GetUrlFromClipboard());
  
  static submitForm = (formData, updateMode) => ahk.SubmitForm(formData, updateMode, Navigationbar.getActiveTab());
  
  static clearBrowsingData = () => ahk.ClearBrowsingData();

  static openFileSelector = () => ahk.sync.OpenFileSelector()
}
