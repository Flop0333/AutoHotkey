#Requires AutoHotkey v2
#Include ..\Support\Assert.ahk
#Include ..\..\Lib\Extensions\Json.ahk
#Include ..\..\Dashboards\Age of Efficiency\Database\BaseDatabaseService.ahk

; Minimal stand-in item class so this test doesn't depend on a full domain model.
class TestItem {
    id := 0
    title := ""
}

NewTempServicePath() => A_Temp "\ahk-basedatabaseservice-test-" A_TickCount "-" Random(1000, 9999) ".json"

Test_StoreThenGetItems_RoundTripsItemData() {
    service := BaseDatabaseService()
    service.STORAGE_FILE_PATH := NewTempServicePath()
    try {
        items := [TestItem(), TestItem()]
        items[1].id := 1, items[1].title := "First"
        items[2].id := 2, items[2].title := "Second"

        service.StoreItems(items)
        result := service.GetItems(TestItem)

        Assert.Equal(2, result.items.Length)
        Assert.Equal("First", result.items[1].title)
        Assert.Equal("Second", result.items[2].title)
        Assert.Equal(2, result.highestId)
    } finally
        try FileDelete(service.STORAGE_FILE_PATH)
}

Test_GetItems_TracksHighestIdRegardlessOfOrder() {
    service := BaseDatabaseService()
    service.STORAGE_FILE_PATH := NewTempServicePath()
    try {
        items := [TestItem(), TestItem(), TestItem()]
        items[1].id := 5, items[2].id := 2, items[3].id := 9

        service.StoreItems(items)
        result := service.GetItems(TestItem)

        Assert.Equal(9, result.highestId)
    } finally
        try FileDelete(service.STORAGE_FILE_PATH)
}

Test_StoreItems_OnEmptyArray_WritesEmptyList() {
    service := BaseDatabaseService()
    service.STORAGE_FILE_PATH := NewTempServicePath()
    try {
        service.StoreItems([])
        result := service.GetItems(TestItem)

        Assert.Equal(0, result.items.Length)
        Assert.Equal(0, result.highestId)
    } finally
        try FileDelete(service.STORAGE_FILE_PATH)
}

TestKit.Run("StoreItems then GetItems round-trips item data", Test_StoreThenGetItems_RoundTripsItemData)
TestKit.Run("GetItems tracks the highest id regardless of array order", Test_GetItems_TracksHighestIdRegardlessOfOrder)
TestKit.Run("StoreItems on an empty array writes an empty, readable list", Test_StoreItems_OnEmptyArray_WritesEmptyList)

TestKit.Report()
