#Include AppsDatabaseService.ahk
#Include ../BaseState.ahk

Class AppsState extends BaseState {

  static state := {apps: [], argumentApps: [], allApps: []}

  static __New() => this.state := AppsDatabaseService().GetApps()

  static Create(app) {
    app.id := this.GetUniqueId()
    this.state.allApps.Push(app)
    if app.argumentRequired
      this.state.argumentApps.Push(app)
    else
      this.state.apps.Push(app)
    this.Store()
  }

  static GetById(id) {
    for item in this.state.allApps
      if item.id = id
        return item
    Throw UnsetError("Item not found by id: " id)
  }

  static GetByCommandOrTitle(input, array := this.state.allApps) {
    for item in array
      if item.command = input || item.title = input
        return item
    return ""
  }

  static GetSuggestionsByCommand(inputCommand, array := this.state.allApps) {
    suggestions := []
    for item in array
      if SubStr(item.command, 1, StrLen(inputCommand)) = inputCommand && inputCommand != item.command
        suggestions.Push(item)
    return suggestions
  }

  static GetByCategory(category) {
    itemsFromCategory := []
    for item in this.state.allApps
      if item.category = category
        itemsFromCategory.Push(item)
    return itemsFromCategory
  }

  static GetCategories() {
    uniqueCategories := []
    for item in this.state.allApps
      if !uniqueCategories.HasValue(item.category) && item.category != ""
        uniqueCategories.Push(item.category)
    return uniqueCategories
  }

  static Update(updatedItem) {
    item := this.GetById(updatedItem.id)
    for key, value in updatedItem.OwnProps()
        item.%key% := value
    this.Store()
  }

  static Delete(deleteTitle) {
    for index, item in this.state.allApps
      if item.title = deleteTitle {
        this.state.allApps.RemoveAt(index)
        this.Store()
        return
      }
    Throw UnsetError("Item not found. title: " deleteTitle)
  }

  static Store() => AppsDatabaseService().StoreApps()
}