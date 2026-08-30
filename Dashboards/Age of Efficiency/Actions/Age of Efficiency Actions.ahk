#Requires AutoHotkey v2

/** Registers the executable actions exposed by Age of Efficiency. */
class AgeOfEfficiencyActions {
    static Register() {
        ActionRegistry.RegisterAll([
            Action("productivity.fake-work-mode.start", "Fake Work Mode", StartFakeWorkMode, {
                description: "Prevent the computer from becoming idle",
                category: "PC Management",
                icon: "Beer",
                aliases: ["fake work"]
            }),
            Action("ui.age-of-efficiency.open", "Age of Efficiency", OpenAgeOfEfficiency, {
                description: "Open the Age of Efficiency dashboard",
                category: "PC Management",
                icon: "AoE"
            }),
            SystemActions.Shutdown(ShutPcDown),
            SystemActions.ReloadStartup(RerunStartup),
            Action("development.status-meme.show", "Status Code Memes", ShowStatusMeme, {
                description: "Show the image for an HTTP status code",
                category: "Dev Tools",
                icon: "Dog",
                argument: ActionArgument.Required("Enter an HTTP status code")
            }),
            Action("development.pbi-reformat.start", "PBI Reformat", StartPBIReformat, {
                description: "Reformat a copied Product Backlog Item as a branch name",
                category: "Dev Tools",
                icon: "VGZ"
            }),
            Action("media.picture-in-picture.start", "Picture in Picture", StartPictureInPicture, {
                description: "Move the active browser video into picture-in-picture mode",
                category: "Media",
                icon: "Youtube"
            }),
            Action("development.remote-desktop.start", "Start VOW", StartRemoteDesktop, {
                description: "Start a configured Remote Desktop connection",
                category: "Dev Tools",
                icon: "Dog",
                argument: ActionArgument.Optional("Remote Desktop setting")
            }),
            Action("productivity.timer.start", "Timer", StartTimer, {
                description: "Start a focus timer for a number of minutes",
                category: "PC Management",
                icon: "Timer",
                argument: ActionArgument.Required("Enter the timer length in minutes")
            }),
            SystemActions.KillAhkProcesses((*) => KillAllAHkProcesses(true))
        ])
    }
}
