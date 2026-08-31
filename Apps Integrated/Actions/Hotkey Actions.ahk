#Requires AutoHotkey v2

class HotkeyActions {
    static Register() {
        ActionRegistry.RegisterAll([
            ApplicationActions.VsCodeZoomIn(),
            ApplicationActions.VsCodeZoomOut(),
            ApplicationActions.CalendarPreviousWeek(),
            ApplicationActions.CalendarNextWeek(),
            ApplicationActions.KeePassMainPassword((*) => KeePass.InsertMainPassword()),
            ApplicationActions.KeePassSecondaryPassword((*) => KeePass.InsertSecondaryPassword())
        ], "Global Hotkeys")
    }
}
