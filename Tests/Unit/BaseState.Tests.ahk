#Requires AutoHotkey v2
#Include ..\Support\Assert.ahk
#Include ..\..\Lib\Extensions\Array.ahk

; BaseState emits user notifications after mutations. Unit tests exercise its
; state behavior without starting the shared logger host.
LogAndNotifyInfo(message) {
}

#Include ..\..\Dashboards\Age of Efficiency\Database\BaseState.ahk

; BaseState.state and BaseState._uniqueId are shared static fields, so every
; test resets them first to avoid leaking state between test cases.
ResetState() {
    BaseState.state := []
    BaseState._uniqueId := 0
}

Test_Create_AssignsIncrementingIds() {
    ResetState()
    BaseState.Create({ title: "First" })
    BaseState.Create({ title: "Second" })
    Assert.Equal(1, BaseState.state[1].id)
    Assert.Equal(2, BaseState.state[2].id)
}

Test_GetById_ReturnsMatchingItem() {
    ResetState()
    BaseState.Create({ title: "Target" })
    Assert.Equal("Target", BaseState.GetById(1).title)
}

Test_GetById_ThrowsWhenNoMatch() {
    ResetState()
    Assert.Throws(() => BaseState.GetById(999))
}

Test_GetByCommandOrTitle_MatchesByCommand() {
    ResetState()
    BaseState.Create({ title: "Title", command: "cmd" })
    Assert.Equal("cmd", BaseState.GetByCommandOrTitle("cmd").command)
}

Test_GetByCommandOrTitle_MatchesByTitle() {
    ResetState()
    BaseState.Create({ title: "Title", command: "cmd" })
    Assert.Equal("Title", BaseState.GetByCommandOrTitle("Title").title)
}

Test_GetByCommandOrTitle_ReturnsEmptyStringWhenNoMatch() {
    ResetState()
    Assert.Equal("", BaseState.GetByCommandOrTitle("missing"))
}

Test_GetSuggestionsByCommand_ReturnsPrefixMatchesExcludingExact() {
    ResetState()
    BaseState.Create({ title: "A", command: "open" })
    BaseState.Create({ title: "B", command: "openApp" })
    BaseState.Create({ title: "C", command: "close" })
    suggestions := BaseState.GetSuggestionsByCommand("open")
    Assert.Equal(1, suggestions.Length)
    Assert.Equal("openApp", suggestions[1].command)
}

Test_GetByCategory_FiltersByCategory() {
    ResetState()
    BaseState.Create({ title: "A", category: "Work" })
    BaseState.Create({ title: "B", category: "Home" })
    items := BaseState.GetByCategory("Work")
    Assert.Equal(1, items.Length)
    Assert.Equal("A", items[1].title)
}

Test_GetCategories_ReturnsUniqueNonEmptyCategories() {
    ResetState()
    BaseState.Create({ title: "A", category: "Work" })
    BaseState.Create({ title: "B", category: "Work" })
    BaseState.Create({ title: "C", category: "Home" })
    BaseState.Create({ title: "D", category: "" })
    categories := BaseState.GetCategories()
    Assert.Equal(2, categories.Length)
    Assert.True(categories.HasValue("Work"))
    Assert.True(categories.HasValue("Home"))
}

Test_Update_MergesPropertiesOntoExistingItem() {
    ResetState()
    BaseState.Create({ title: "Original", category: "Work" })
    BaseState.Update({ id: 1, title: "Updated" })
    Assert.Equal("Updated", BaseState.GetById(1).title)
    Assert.Equal("Work", BaseState.GetById(1).category)
}

Test_Delete_RemovesMatchingItem() {
    ResetState()
    BaseState.Create({ title: "ToDelete" })
    BaseState.Delete("ToDelete")
    Assert.Equal(0, BaseState.state.Length)
}

Test_Delete_ThrowsWhenNoMatch() {
    ResetState()
    Assert.Throws(() => BaseState.Delete("missing"))
}

TestKit.Run("Create assigns incrementing ids to new items", Test_Create_AssignsIncrementingIds)
TestKit.Run("GetById returns the matching item", Test_GetById_ReturnsMatchingItem)
TestKit.Run("GetById throws when no item matches", Test_GetById_ThrowsWhenNoMatch)
TestKit.Run("GetByCommandOrTitle matches by command", Test_GetByCommandOrTitle_MatchesByCommand)
TestKit.Run("GetByCommandOrTitle matches by title", Test_GetByCommandOrTitle_MatchesByTitle)
TestKit.Run("GetByCommandOrTitle returns an empty string when nothing matches", Test_GetByCommandOrTitle_ReturnsEmptyStringWhenNoMatch)
TestKit.Run("GetSuggestionsByCommand returns prefix matches excluding the exact match", Test_GetSuggestionsByCommand_ReturnsPrefixMatchesExcludingExact)
TestKit.Run("GetByCategory filters items by category", Test_GetByCategory_FiltersByCategory)
TestKit.Run("GetCategories returns unique, non-empty categories", Test_GetCategories_ReturnsUniqueNonEmptyCategories)
TestKit.Run("Update merges new properties onto the existing item", Test_Update_MergesPropertiesOntoExistingItem)
TestKit.Run("Delete removes the item with the matching title", Test_Delete_RemovesMatchingItem)
TestKit.Run("Delete throws when no item matches the title", Test_Delete_ThrowsWhenNoMatch)

TestKit.Report()
