#Include ..\Lib\Core\Paths.ahk
#Include ..\Lib\Tools\Info.ahk

class StartupMessage extends Gui {
    BACKGROUND_PATH := Paths.startup "\background.gif"
    WIDTH := A_ScreenWidth / 2.5
    HEIGHT := this.WIDTH / 3
    SHOW_TIME_INIT_MESSAGE := 4000 ; ms
    SHOW_TIME_SUCCES_MESSAGE := 4000 ; ms

    __New() {
        super.__New("-Caption +AlwaysOnTop" , "Startup AutoHotkey")

        ; Set background gif, made using https://edit.funimada.com/editable-gif-backgrounds/background-1004.html
        wb := this.AddActiveX("x0 y0 h" this.HEIGHT " w" This.WIDTH, "Shell.Explorer")
        wb.Value.Navigate("about:blank")
        wb.Value.document.write('<html><body style="margin:0;padding:0;overflow:hidden;background:black"><img src="file:///' StrReplace(this.BACKGROUND_PATH, "\", "/") '" style="height:' this.HEIGHT 'px;width:' this.WIDTH 'px;display:block"></body></html>')

        ; Round corners
        WinSetRegion("0-0 w" this.WIDTH " h" this.HEIGHT " r40-40", this)

        this.Show("w" this.WIDTH " h" this.HEIGHT " y" A_ScreenHeight/10 " x" (A_ScreenWidth - this.WIDTH)/2)
        SetTimer(() => this._ShowSuccesThenClose(), -this.SHOW_TIME_INIT_MESSAGE)
    }

    _ShowSuccesThenClose() {
        this.Destroy() 
        Info("AutoHotkey initialized`n`n" "Profile: " ProfileManager.current.displayName, this.SHOW_TIME_SUCCES_MESSAGE)
    }
}