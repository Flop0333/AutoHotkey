#Include ..\..\Lib\Core\OnError.ahk
#Include ..\..\Lib\Core\Paths.ahk
#Include ..\..\Lib\Core\Persistent WebView.ahk
#Include ..\..\Secrets\Secrets Service.ahk

class NotionBoardController extends PersistentWebView {
    static WIN_TITLE := "Notion Board"
    ; Fixed, git-ignored profile folder derived through Paths.ahk. Cookies and
    ; session state land here instead of in a per-process temp folder, so a
    ; single manual login survives a full suite restart.
    static PROFILE_DIR := Paths.dashboards "\Notion Board\Profile"
    static SHOW_OPTIONS := Format("w{} h{}", Round(A_ScreenWidth * 0.85), Round(A_ScreenHeight * 0.85))

    __New() {
        super.__New(NotionBoardController.PROFILE_DIR)
        this.Gui.Title := NotionBoardController.WIN_TITLE
        this.Gui.OnEvent("Close", (*) => this.Hide())
        this.LoadBoard()
    }

    Show() => super.Show(NotionBoardController.SHOW_OPTIONS, NotionBoardController.WIN_TITLE)

    ; Starts hidden with the suite so the first CapsLock+N is instant.
    InitializeHidden() {
        super.Show("Hide " NotionBoardController.SHOW_OPTIONS, NotionBoardController.WIN_TITLE)
        this.IsVisible := false
    }

    Close() => this.Hide()

    ; Loads the board from the NotionBoardUrl secret. Secret.Get() already
    ; logs and notifies when the value is missing; this also keeps the window
    ; itself from opening blank by showing a short notice on the page.
    LoadBoard() {
        url := Secrets.NotionBoardUrl.Get()
        if (url = "") {
            this.NavigateToString('<html><body style="margin:0;height:100vh;display:flex;align-items:center;justify-content:center;background:#1b1b1b;color:#eee;font-family:sans-serif;text-align:center;"><p>The <code>NotionBoardUrl</code> secret is not configured.<br>Add it and restart the Notion Board.</p></body></html>')
            return false
        }
        this.Load(url)
        return true
    }
}
