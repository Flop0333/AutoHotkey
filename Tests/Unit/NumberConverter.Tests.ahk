#Requires AutoHotkey v2
#Include ..\Support\Assert.ahk
#Include ..\..\Lib\Helpers\Number Convertor.ahk

TestKit.Run("DecToHex converts with a 0x prefix by default", () => Assert.Equal("0xff", NumberConverter.DecToHex(255)))
TestKit.Run("DecToHex can omit the prefix", () => Assert.Equal("ff", NumberConverter.DecToHex(255, false)))
TestKit.Run("DecToHex handles zero", () => Assert.Equal("0x0", NumberConverter.DecToHex(0)))
TestKit.Run("DecToHex handles large numbers", () => Assert.Equal("0x100000", NumberConverter.DecToHex(1048576)))

TestKit.Run("HexToDec converts a 0x-prefixed hex string to decimal", () => Assert.Equal("255", NumberConverter.HexToDec("0xff")))
TestKit.Run("HexToDec handles zero", () => Assert.Equal("0", NumberConverter.HexToDec("0x0")))
TestKit.Run("HexToDec and DecToHex round-trip", () => Assert.Equal("4096", NumberConverter.HexToDec(NumberConverter.DecToHex(4096))))

TestKit.Report()
