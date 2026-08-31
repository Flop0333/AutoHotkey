#Requires AutoHotkey v2

/** Canonical definitions for reusable development workflow actions. */
class DevelopmentActions {
    static StatusMeme(execute) => Action(ActionIds.Development.StatusMemeShow, "Status Code Memes", execute, {
        description: "Show the image for an HTTP status code", category: "Development", icon: "Dog",
        argument: ActionArgument.Required("Enter an HTTP status code")
    })
    static PbiReformat(execute) => Action(ActionIds.Development.PbiReformatStart, "PBI Reformat", execute, {
        description: "Reformat a copied Product Backlog Item as a branch name", category: "Development", icon: "VGZ"
    })
    static RemoteDesktop(execute) => Action(ActionIds.Development.RemoteDesktopStart, "Start VOW", execute, {
        description: "Start a configured Remote Desktop connection", category: "Development", icon: "Dog",
        argument: ActionArgument.Optional("Remote Desktop setting")
    })
    static CommandStorer(execute) => Action(ActionIds.Development.CommandStorerOpen, "Command Storer", execute, {
        description: "Open the saved command collection", category: "Development", icon: "tetris.gif"
    })
}
