#Requires AutoHotkey v2
#Include ..\Support\Assert.ahk
#Include ..\..\Lib\Core\Paths.ahk
#Include ..\..\Lib\Extensions\Json.ahk

; AHK v2 fully parses the merged script - including code paths this test
; never executes - before running anything, and requires every referenced
; global to resolve. Secrets File Manager.ahk calls the real Info() toast
; helper (Lib/Tools/Info.ahk, a GUI popup) and reads the real SecretsCatalog
; (Secrets Catalog.ahk, which itself needs the full Secret class). Stub both
; instead of pulling those dependencies into a unit test that never touches them.
Info(text, timeout := 0) {
}
SecretsCatalog := Map()

#Include ..\..\Secrets\Secrets File Manager.ahk

; _IsValidSecretsJson and _AhkStringLiteral are the only real logic in this
; file (everything else is file/mutex I/O), so they're exercised directly even
; though they're private-by-convention (leading underscore).

TestKit.Run("Valid: empty object", () => Assert.True(SecretsFileManager._IsValidSecretsJson("{}")))
TestKit.Run("Valid: single string key-value pair", () => Assert.True(SecretsFileManager._IsValidSecretsJson('{"key": "value"}')))
TestKit.Run("Valid: multiple string key-value pairs", () => Assert.True(SecretsFileManager._IsValidSecretsJson('{"a": "1", "b": "2"}')))
TestKit.Run("Valid: tolerates surrounding whitespace and newlines", () => Assert.True(SecretsFileManager._IsValidSecretsJson("`n  { `"a`" : `"1`" } `n")))
TestKit.Run("Valid: string values may contain escape sequences", () => Assert.True(SecretsFileManager._IsValidSecretsJson('{"a": "line1\nline2\ttabbed"}')))
TestKit.Run("Valid: array-of-strings value", () => Assert.True(SecretsFileManager._IsValidSecretsJson('{"key": ["secret1", "secret2"]}')))
TestKit.Run("Valid: empty array value", () => Assert.True(SecretsFileManager._IsValidSecretsJson('{"key": []}')))
TestKit.Run("Valid: single-element array value", () => Assert.True(SecretsFileManager._IsValidSecretsJson('{"key": ["secret1"]}')))
TestKit.Run("Valid: mix of string and array values", () => Assert.True(SecretsFileManager._IsValidSecretsJson('{"a": "1", "b": ["2", "3"]}')))

TestKit.Run("Invalid: top-level array is rejected", () => Assert.True(SecretsFileManager._IsValidSecretsJson("[]") != true))
TestKit.Run("Invalid: numeric value is rejected", () => Assert.True(SecretsFileManager._IsValidSecretsJson('{"key": 123}') != true))
TestKit.Run("Invalid: boolean value is rejected", () => Assert.True(SecretsFileManager._IsValidSecretsJson('{"key": true}') != true))
TestKit.Run("Invalid: nested object value is rejected", () => Assert.True(SecretsFileManager._IsValidSecretsJson('{"key": {}}') != true))
TestKit.Run("Invalid: trailing comma is rejected", () => Assert.True(SecretsFileManager._IsValidSecretsJson('{"key": "value",}') != true))
TestKit.Run("Invalid: missing colon is rejected", () => Assert.True(SecretsFileManager._IsValidSecretsJson('{"key" "value"}') != true))
TestKit.Run("Invalid: unterminated string is rejected", () => Assert.True(SecretsFileManager._IsValidSecretsJson('{"key": "value') != true))
TestKit.Run("Invalid: empty text is rejected", () => Assert.True(SecretsFileManager._IsValidSecretsJson("") != true))
TestKit.Run("Invalid: trailing garbage after the closing brace is rejected", () => Assert.True(SecretsFileManager._IsValidSecretsJson('{"key":"value"}garbage') != true))
TestKit.Run("Invalid: array with a non-string element is rejected", () => Assert.True(SecretsFileManager._IsValidSecretsJson('{"key": ["a", 1]}') != true))
TestKit.Run("Invalid: array with a nested array is rejected", () => Assert.True(SecretsFileManager._IsValidSecretsJson('{"key": ["a", []]}') != true))
TestKit.Run("Invalid: array with trailing comma is rejected", () => Assert.True(SecretsFileManager._IsValidSecretsJson('{"key": ["a",]}') != true))
TestKit.Run("Invalid: unterminated array is rejected", () => Assert.True(SecretsFileManager._IsValidSecretsJson('{"key": ["a", "b"}') != true))

Test_IsValidSecretValue_AcceptsString() {
    Assert.True(SecretsFileManager._IsValidSecretValue("value"))
}

Test_IsValidSecretValue_AcceptsArrayOfStrings() {
    Assert.True(SecretsFileManager._IsValidSecretValue(["secret1", "secret2"]))
}

Test_IsValidSecretValue_AcceptsEmptyArray() {
    Assert.True(SecretsFileManager._IsValidSecretValue([]))
}

Test_IsValidSecretValue_RejectsArrayWithNonStringElement() {
    Assert.True(SecretsFileManager._IsValidSecretValue(["a", 1]) != true)
}

Test_IsValidSecretValue_RejectsNumber() {
    Assert.True(SecretsFileManager._IsValidSecretValue(123) != true)
}

Test_IsValidSecretValue_RejectsMap() {
    Assert.True(SecretsFileManager._IsValidSecretValue(Map()) != true)
}

TestKit.Run("IsValidSecretValue accepts a string", Test_IsValidSecretValue_AcceptsString)
TestKit.Run("IsValidSecretValue accepts an array of strings", Test_IsValidSecretValue_AcceptsArrayOfStrings)
TestKit.Run("IsValidSecretValue accepts an empty array", Test_IsValidSecretValue_AcceptsEmptyArray)
TestKit.Run("IsValidSecretValue rejects an array with a non-string element", Test_IsValidSecretValue_RejectsArrayWithNonStringElement)
TestKit.Run("IsValidSecretValue rejects a number", Test_IsValidSecretValue_RejectsNumber)
TestKit.Run("IsValidSecretValue rejects a map", Test_IsValidSecretValue_RejectsMap)

Test_AhkStringLiteral_EscapesEmbeddedDoubleQuotes() {
    backtick := Chr(96), quote := Chr(34)
    input := "He said " quote "hi" quote
    expected := quote "He said " backtick quote "hi" backtick quote quote
    Assert.Equal(expected, SecretsFileManager._AhkStringLiteral(input))
}

Test_AhkStringLiteral_EscapesNewlinesAndTabs() {
    backtick := Chr(96), quote := Chr(34)
    input := "line1`nline2`ttabbed"
    expected := quote "line1" backtick "n" "line2" backtick "t" "tabbed" quote
    Assert.Equal(expected, SecretsFileManager._AhkStringLiteral(input))
}

Test_AhkStringLiteral_EscapesALiteralBacktick() {
    backtick := Chr(96), quote := Chr(34)
    input := "a" backtick "b"
    expected := quote "a" backtick backtick "b" quote
    Assert.Equal(expected, SecretsFileManager._AhkStringLiteral(input))
}

Test_AhkStringLiteral_LeavesPlainTextUnchanged() {
    Assert.Equal('"hello world"', SecretsFileManager._AhkStringLiteral("hello world"))
}

TestKit.Run("AhkStringLiteral escapes embedded double quotes", Test_AhkStringLiteral_EscapesEmbeddedDoubleQuotes)
TestKit.Run("AhkStringLiteral escapes newlines and tabs", Test_AhkStringLiteral_EscapesNewlinesAndTabs)
TestKit.Run("AhkStringLiteral escapes a literal backtick", Test_AhkStringLiteral_EscapesALiteralBacktick)
TestKit.Run("AhkStringLiteral leaves plain text unchanged", Test_AhkStringLiteral_LeavesPlainTextUnchanged)

TestKit.Report()
