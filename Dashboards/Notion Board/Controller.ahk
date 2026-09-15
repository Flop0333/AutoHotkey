#Include ..\..\Lib\Core\OnError.ahk
#Include ..\..\Lib\Core\Paths.ahk
#Include ..\..\Lib\Core\Persistent WebView.ahk
#Include ..\..\Lib\Tools\Window Settings Service.ahk
#Include ..\..\Lib\Tools\Window State Tracker.ahk
#Include ..\..\Secrets\Secrets Service.ahk

class NotionBoardController extends PersistentWebView {
    static WIN_TITLE := "Notion Board"
    static WM_SYSCOMMAND := 0x0112
    static SC_MINIMIZE := 0xF020
    static SC_CLOSE := 0xF060
    ; Fixed, git-ignored browser-data folder derived through Paths.ahk. Cookies
    ; and session state land here instead of in a per-process temp folder, so a
    ; single manual login survives a full suite restart.
    static BROWSER_DATA_DIR := Paths.dashboards "\Notion Board\Browser Data"
    static SETTINGS_PATH := Paths.dashboards "\Notion Board\window settings.ini"
    
    ; Script to hide elements from Notion to show only a focus view
    static HIDE_NOTION_CHROME_SCRIPT := "
    (
    (() => {
        const styleId = 'notion-board-focus-style';
        const installStyle = () => {
            if (!document.head) {
                requestAnimationFrame(installStyle);
                return;
            }
            if (document.getElementById(styleId))
                return;

            const style = document.createElement('style');
            style.id = styleId;
            style.textContent = 'header:has(.notion-topbar), .notion-topbar, .notion-assistant-corner-origin-container, .notion-page-controls, .content-editable-void-no-select, nav.notion-sidebar-container[aria-label=\'Sidebar\'], aside[aria-label=\'Page comments\'] { display: none !important; }';
            document.head.appendChild(style);
        };
        installStyle();
    })();
    )"

    __New(settingsPath := NotionBoardController.SETTINGS_PATH) {
        super.__New(NotionBoardController.BROWSER_DATA_DIR,,,,false) ; false to set default caption
        this.Gui.Title := NotionBoardController.WIN_TITLE
        defaultWidth := Round(A_ScreenWidth * 0.85)
        defaultHeight := Round(A_ScreenHeight * 0.85)
        defaultX := Round((A_ScreenWidth - defaultWidth) / 2)
        defaultY := Round((A_ScreenHeight - defaultHeight) / 2)
        this.settingsService := WindowSettingsService(
            settingsPath, defaultWidth, defaultHeight, defaultX, defaultY)
        this.showOptions := Format("x{} y{} w{} h{}",
            this.settingsService.Window.x,
            this.settingsService.Window.y,
            this.settingsService.Window.Width,
            this.settingsService.Window.Height)
        this.windowPositionTracker := WindowPositionTracker(this.Gui, this.settingsService)
        this.Gui.OnEvent("Close", (*) => this.SendToDesktop())
        this.Gui.OnEvent("Escape", (*) => this.SendToDesktop())
        this.SystemCommandHandler := ObjBindMethod(this, "HandleSystemCommand")
        OnMessage(NotionBoardController.WM_SYSCOMMAND, this.SystemCommandHandler)
        this.AddScriptToExecuteOnDocumentCreated(NotionBoardController.HIDE_NOTION_CHROME_SCRIPT, 0)
        this.LoadBoard()
    }


    ToggleNotionBoard() => WinActive("ahk_id " myNotionBoard.Hwnd) ? myNotionBoard.SendToDesktop() WinActivate("ahk_class Shell_TrayWnd") : myNotionBoard.Show()
    
    Show() {
        this.IsVisible := true
        this.Gui.GetPos(&x, &y, &width, &height)
        currentOptions := Format("x{} y{} w{} h{}", x, y, width, height)
        super.Show(currentOptions, NotionBoardController.WIN_TITLE)
    }

    Hide() {
        this.SendToDesktop()
    }

    ; Starts behind all other application windows, where it remains visible as
    ; part of the desktop whenever those windows do not cover it.
    InitializeOnDesktop() {
        super.Show("NA " this.showOptions, NotionBoardController.WIN_TITLE)
        this.SendToDesktop()
    }

    Close() => this.SendToDesktop()

    Minimize() => this.SendToDesktop()

    SendToDesktop() {
        if (WinGetMinMax("ahk_id " this.Hwnd) = -1)
            this.Gui.Restore()
        this.IsVisible := true
        this.Gui.Show("NA")
        WinMoveBottom("ahk_id " this.Hwnd)
    }

    HandleSystemCommand(wParam, lParam, msg, hwnd) {
        if (hwnd != this.Hwnd)
            return

        command := wParam & 0xFFF0
        if (command = NotionBoardController.SC_MINIMIZE
            || command = NotionBoardController.SC_CLOSE) {
            this.SendToDesktop()
            return 0
        }
    }

    ; Loads the board from the NotionBoardUrl secret. Secret.Get() already
    ; logs and notifies when the value is missing; this also keeps the window
    ; itself from opening blank by showing a short notice on the page.
    LoadBoard() {
        url := Secrets.NotionBoardUrl.Get()
        if (url = "") {
            LogAndNotifyWarning("Notion bord url is not set!")
            return false
        }
        this.Load(url)
        return true
    }
}
