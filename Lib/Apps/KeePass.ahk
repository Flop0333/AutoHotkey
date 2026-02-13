#Include App.ahk
#Include ..\Tools\UIA-v2\Lib\UIA.ahk

class KeePass extends App {
	static __New() => App.Init(
		winTitle := "Database.kdbx - KeePass",
		ahk_exe := "KeePass.exe"
	)

    static InsertMainPassword() => this._InsertPassword(true)
    static InsertSecondaryPassword() => this._InsertPassword(false)

    static _InsertPassword(mainPassword := true) {
        this.Activate()
        KeePassEl := UIA.ElementFromHandle(this.winTitle " ahk_exe " this.ahk_exe)
        KeePassEl.ElementFromPath("YYYYNOO").Select()
        this.Activate()
        Send("{Right}")
        Sleep(40)
        mainPassword ? KeePassEl.ElementFromPath("YYYY/87q").Select() : KeePassEl.ElementFromPath("YYYY/87").Select()
        Send("LAlt Up")
        Send("^c") ; TODO: get text from element instead of using clipboard
        this.Minimize()
        Send("^v") ; TODO: use ClipSend when text is obtained directly
        Sleep(50)
        Send("{Enter}")
    }
}
