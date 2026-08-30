#Requires AutoHotkey v2

class AppHotkeyActions {
    static Register() {
        ActionRegistry.RegisterAll([
            Action("notion.sidebar.toggle", "Toggle Notion Sidebar", (*) => Send("^\"), {category: "Notion"}),
            Action("teams.microphone.toggle", "Mute or Unmute Teams", (*) => Send("^+m"), {category: "Teams"}),
            Action("vscode.project-action.primary", "Run Primary Project Action", RunVsCodePrimaryAction, {category: "VS Code"}),
            Action("vscode.project-action.secondary", "Run Secondary Project Action", RunVsCodeSecondaryAction, {category: "VS Code"})
        ])
    }
}
