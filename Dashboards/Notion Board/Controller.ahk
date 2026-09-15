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
            style.textContent = 'header:has(.notion-topbar), .notion-topbar, .notion-assistant-corner-origin-container, .notion-page-controls, .content-editable-void-no-select, .layout-content.layout-content-with-divider, [aria-roledescription=\'page title\'], nav.notion-sidebar-container[aria-label=\'Sidebar\'], aside[aria-label=\'Page comments\'] { display: none !important; } .notion-board-view { margin: 5px !important; }';
            document.head.appendChild(style);
        };
        installStyle();
    })();
    )"

    __New(settingsPath := NotionBoardController.SETTINGS_PATH) {
        super.__New(NotionBoardController.BROWSER_DATA_DIR,,,,false) ; false to set default caption
        this.Gui.Title := NotionBoardController.WIN_TITLE
        this.EnableDarkCaption()
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

    EnableDarkCaption() {
        enabled := Buffer(4, 0)
        NumPut("Int", 1, enabled)
        result := DllCall("dwmapi\DwmSetWindowAttribute",
            "Ptr", this.Hwnd,
            "Int", 20, ; DWMWA_USE_IMMERSIVE_DARK_MODE
            "Ptr", enabled,
            "Int", enabled.Size,
            "Int")
        if (result != 0) {
            DllCall("dwmapi\DwmSetWindowAttribute",
                "Ptr", this.Hwnd,
                "Int", 19, ; Fallback for older Windows 10 builds
                "Ptr", enabled,
                "Int", enabled.Size,
                "Int")
        }
    }

    ToggleNotionBoard() => WinActive("ahk_id " myNotionBoard.Hwnd) ? myNotionBoard.SendToDesktop() WinActivate("ahk_class Shell_TrayWnd") : myNotionBoard.Show()
    
    Show() {
        this.IsVisible := true
        ; The GUI already has its restored geometry. Passing that geometry back
        ; through WebViewToo.Show() would apply its border adjustment again and
        ; make the window drift slightly on every toggle.
        this.Gui.Show()
        WinActivate("ahk_id " this.Hwnd)
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
