#Requires AutoHotkey v2
#SingleInstance Off
#Include ..\..\Lib\Core\OnError.ahk

try {
	writerId := A_Args[1]
	entryCount := Integer(A_Args[2])
	loop entryCount
		LogInfo(writerId "-" A_Index)
	ExitApp(0)
} catch as writerError {
	FileAppend(writerId ": " writerError.Message "`n" writerError.Stack "`n", "**")
	ExitApp(2)
}
