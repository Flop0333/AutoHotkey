#Requires AutoHotkey v2

/** Stable action identifiers used by AutoHotkey source code. */
class ActionIds {
    class System {
        static RegistryDiagnostics := "system.action-registry-diagnostics"
        static CapsLockOff := "system.caps-lock.off"
        static KillAhkProcesses := "system.kill-ahk-processes"
        static ReloadStartup := "system.reload-startup"
        static Shutdown := "system.shutdown"
    }

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

    class Desktop {
        static Previous := "desktop.previous"
        static TogglePinWindow := "desktop.pin-window.toggle"
    }

    class Productivity {
        static TimerStart := "productivity.timer.start"
        static FakeWorkStart := "productivity.fake-work-mode.start"
        static FakeWorkToggle := "productivity.fake-work-mode.toggle"
        static ScreenOcrCapture := "productivity.screen-ocr.capture"
        static ScreenSnipCopy := "productivity.screen-snip.copy"
        static ScreenSnipCopyOnly := "productivity.screen-snip.copy-only"
        static ScreenSnipSave := "productivity.screen-snip.save"
    }

    class Media {
        static PictureInPictureStart := "media.picture-in-picture.start"
    }

    class Writing {
        static SpellCheckerToggle := "writing.spell-checker.toggle"
    }

    class Development {
        static CommandStorerOpen := "development.command-storer.open"
        static PbiReformatStart := "development.pbi-reformat.start"
        static RemoteDesktopStart := "development.remote-desktop.start"
        static StatusMemeShow := "development.status-meme.show"
    }

    class Ui {
        static AgeOfEfficiencyOpen := "ui.age-of-efficiency.open"
    }

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

    class Demo {
        static Pizza := "demo.pizza"
    }
}
