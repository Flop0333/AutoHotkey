#Requires AutoHotkey v2

/** Stable action identifiers used by AutoHotkey source code. */
class ActionIds {
    /** IDs for registry diagnostics, lifecycle, and machine-level behavior. */
    class System {
        static RegistryDiagnostics := "system.action-registry-diagnostics"
        static CapsLockOff := "system.caps-lock.off"
        static KillAhkProcesses := "system.kill-ahk-processes"
        static ReloadStartup := "system.reload-startup"
        static Shutdown := "system.shutdown"
    }

    /** IDs for manipulating ordinary application windows. */
    class Window {
        static DragUnderMouse := "window.drag-under-mouse"
        static ResizeUnderMouse := "window.resize-under-mouse"
        static CloseUnderMouse := "window.close-under-mouse"
        static ToggleAlwaysOnTop := "window.always-on-top.toggle"
        static MoveToLeftMonitor := "window.move-to-left-monitor"
        static MoveToRightMonitor := "window.move-to-right-monitor"
        static MaximizeUnderMouse := "window.maximize-under-mouse"
        static MinimizeUnderMouse := "window.minimize-under-mouse"
    }

    /** IDs for virtual-desktop behavior. */
    class Desktop {
        static Previous := "desktop.previous"
        static TogglePinWindow := "desktop.pin-window.toggle"
    }

    /** IDs for timers, screen capture, and focused-work tools. */
    class Productivity {
        static TimerStart := "productivity.timer.start"
        static FakeWorkStart := "productivity.fake-work-mode.start"
        static FakeWorkToggle := "productivity.fake-work-mode.toggle"
        static ScreenOcrCapture := "productivity.screen-ocr.capture"
        static ScreenSnipCopy := "productivity.screen-snip.copy"
        static ScreenSnipCopyOnly := "productivity.screen-snip.copy-only"
        static ScreenSnipSave := "productivity.screen-snip.save"
    }

    /** IDs for media behavior that is not tied to one application. */
    class Media {
        static PictureInPictureStart := "media.picture-in-picture.start"
    }

    /** IDs for text and writing assistance. */
    class Writing {
        static SpellCheckerToggle := "writing.spell-checker.toggle"
    }

    /** IDs for development workflow tools. */
    class Development {
        static CommandStorerOpen := "development.command-storer.open"
        static PbiReformatStart := "development.pbi-reformat.start"
        static RemoteDesktopStart := "development.remote-desktop.start"
        static StatusMemeShow := "development.status-meme.show"
    }

    /** IDs that open or control suite-owned user interfaces. */
    class Ui {
        static AgeOfEfficiencyOpen := "ui.age-of-efficiency.open"
    }

    /** IDs associated with a particular external application or website. */
    class Application {
        static BrowserCloseAll := "browser.close-all"
        static CalendarOpen := "calendar.open"
        static CalendarPreviousWeek := "calendar.previous-week"
        static CalendarNextWeek := "calendar.next-week"
        static ChatGptOpen := "chatgpt.open"
        static FinancesOpen := "personal.finances.open"
        static MapsOpen := "maps.open"
        static WeatherOpen := "weather.open"
        static WhatsAppOpen := "whatsapp.open"
        static KeePassMainPassword := "keepass.main-password.insert"
        static KeePassSecondaryPassword := "keepass.secondary-password.insert"
        static NotionOpen := "notion.open"
        static NotionSidebarToggle := "notion.sidebar.toggle"
        static NotionShitFixenOpen := "notion.shit-fixen.open"
        static NotionWorkDashboardOpen := "notion.work-dashboard.open"
        static SpotifyOpen := "spotify.open"
        static SpotifyGoodMorningJazz := "spotify.good-morning-jazz.start"
        static TeamsMicrophoneToggle := "teams.microphone.toggle"
        static VsCodeOpen := "vscode.open"
        static VsCodeAutoHotkeyOpen := "vscode.autohotkey.open"
        static VsCodeZoomIn := "vscode.zoom-in"
        static VsCodeZoomOut := "vscode.zoom-out"
        static VsCodePrimaryAction := "vscode.project-action.primary"
        static VsCodeSecondaryAction := "vscode.project-action.secondary"
    }

    /** Non-production examples used to demonstrate registry integration. */
    class Demo {
        static Pizza := "demo.pizza"
    }
}
