#Requires AutoHotkey v2

class AppHotkeyActions {
    static Register() {
        ActionRegistry.RegisterAll([
            ApplicationActions.NotionSidebarToggle((*) => Send("^\")),
            ApplicationActions.TeamsMicrophoneToggle((*) => Send("^+m")),
            ApplicationActions.VsCodePrimaryAction(RunVsCodePrimaryAction),
            ApplicationActions.VsCodeSecondaryAction(RunVsCodeSecondaryAction)
        ], "App Hotkeys")
    }
}
