#Requires AutoHotkey v2
#Include ..\Support\Assert.ahk
#Include ..\..\Lib\Extensions\Array.ahk

TestKit.Run("ToString joins elements with the default separator", () => Assert.Equal("1, 2, 3", [1, 2, 3].ToString()))
TestKit.Run("ToString joins elements with a custom separator", () => Assert.Equal("a|b", ["a", "b"].ToString("|")))
TestKit.Run("ToString on a single-element array returns that element", () => Assert.Equal("only", ["only"].ToString()))
TestKit.Run("ToString on an empty array returns an empty string", () => Assert.Equal("", [].ToString()))

TestKit.Run("HasValue finds an existing value", () => Assert.True([1, 2, 3].HasValue(2)))
TestKit.Run("HasValue returns false for a missing value", () => Assert.False([1, 2, 3].HasValue(9)))
TestKit.Run("HasValue on an empty array returns false", () => Assert.False([].HasValue(1)))
TestKit.Run("HasValue matches strings", () => Assert.True(["a", "b", "c"].HasValue("b")))

TestKit.Report()
