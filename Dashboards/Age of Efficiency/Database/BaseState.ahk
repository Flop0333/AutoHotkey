; Base class for in memorystate management of database entities
; Provides common CRUD operations and ID management

#Include ..\..\..\Lib\Extensions\Singleton.ahk

Class BaseState extends Singleton {

  static state := [] ; In-memory storage, override in subclasses
  static _uniqueId := 0 ; Tracks unique IDs for new items

  static GetUniqueId() => ++this._uniqueId
  static SetUniqueId(id) => this._uniqueId := id

  static Create(item) {
    item.id := this.GetUniqueId()
    this.state.Push(item)
    this.Store()
  }

  static GetById(id) {
    for item in this.state
      if item.id = id
        return item
    Throw UnsetError("Item not found by id: " id)
  }

  static GetByCommandOrTitle(input) {
    for item in this.state
      if item.command = input || item.title = input
        return item
    return ""
  }

  static GetSuggestionsByCommand(inputCommand) {
    suggestions := []
    for item in this.state
      if SubStr(item.command, 1, StrLen(inputCommand)) = inputCommand && inputCommand != item.command
        suggestions.Push(item)
    return suggestions
  }

  static GetByCategory(category) {
    itemsFromCategory := []
    for item in this.state
      if item.category = category
        itemsFromCategory.Push(item)
    return itemsFromCategory
  }

  static GetCategories() {
    uniqueCategories := []
    for item in this.state
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
    for index, item in this.state
      if item.title = deleteTitle {
        this.state.RemoveAt(index)
        this.Store()
        return
      }
    Throw UnsetError("Item not found. title: " deleteTitle)
  }

  ; Persists state to storage (override in subclasses)
  static Store() => {}
}