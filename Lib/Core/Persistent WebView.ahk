#Requires AutoHotkey v2
#Include WebView.ahk

; A WebViewToo host with a caller-supplied, persistent user data folder,
; instead of WebViewToo's per-process temp folder. Cookies and session state
; then survive a restart, so a site that needs a login only needs it once.
;
; WebViewToo computes its user data folder as a local variable inside its own
; __New(), so a subclass cannot override just that value without skipping
; super.__New() entirely. This __New() is therefore a deliberate copy of
; WebViewToo's __New() (see Lib/Tools/WebView/WebViewToo.ahk) with only the
; user data folder replaced by a parameter. Keep it in sync if that method
; changes.
class PersistentWebView extends WebViewToo {
    __New(UserDataDir, Html := WebViewToo.Template.HTML, CSS := WebViewToo.Template.CSS, JS := WebViewToo.Template.JS, CustomCaption := True) {
        this.Gui := Gui("+Resize")
        this.Gui.BackColor := "000000"
        this.CustomCaption := CustomCaption
        this.Gui.MarginX := this.Gui.MarginY := 0
        this.Gui.BorderSize := 0, this.MaximizedBorderSize := 7
        this.Gui.Add("Button", "x0 y0 vNCLBUTTONDOWN_Sink Hidden", "John Cena")
        this.Gui.Add("Text", "x" this.BorderSize " y" this.BorderSize " vWebViewTooContainer BackgroundTrans", "If you can see this, something went wrong.")
        this.wvc := !A_IsCompiled
            ? WebView2.create(this.Gui["WebViewTooContainer"].Hwnd,,, UserDataDir)
            : WebView2.create(this.Gui["WebViewTooContainer"].Hwnd,,, UserDataDir,,, WebViewToo.DllPath)
        this.IsVisible := 1, this.wv := this.wvc.CoreWebView2
        this.Gui.OnEvent("Size", (*) => this.Fill())
        this.AddCallbackToScript("Close", this.Close)
        this.AddCallbackToScript("DragWindow", this.DragWindow)
        this.AddCallbackToScript("Minimize", this.Minimize)
        this.AddCallbackToScript("Maximize", this.Maximize)
        this.AddScriptToExecuteOnDocumentCreated("const ahk = window.chrome.webview.hostObjects", 0)
        this.wv.NavigateToString(Format(WebViewToo.Template.Framework, Html, CSS, JS))
        if (this.CustomCaption) {
            this.CustomCaptionBarInit()
        }
    }
}
