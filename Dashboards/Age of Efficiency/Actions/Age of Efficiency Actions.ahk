#Requires AutoHotkey v2

/** Registers the executable actions exposed by Age of Efficiency. */
class AgeOfEfficiencyActions {
    static Register() {
        ActionRegistry.RegisterAll([
            ProductivityActions.FakeWorkStart((*) => FakeWorkMode.Start()),
            Action("ui.age-of-efficiency.open", "Age of Efficiency", (*) => aoeWindow.Show(), {
                description: "Open the Age of Efficiency dashboard",
                category: "PC Management",
                icon: "AoE"
            }),
            SystemActions.Shutdown((*) => System.PowerDown()),
            SystemActions.CapsLockOff((*) => SetCapsLockState("Off")),
            SystemActions.ReloadStartup((*) => RunStartup()),
            DevelopmentActions.StatusMeme((statusCode) => StatusMeme(statusCode)),
            DevelopmentActions.PbiReformat((*) => PBIReformat.Start()),
            ProductivityActions.PictureInPicture(PictureInPicture),
            DevelopmentActions.RemoteDesktop((setting := "H3") => VirtualMachine.StartRemoteDesktop(setting)),
            ProductivityActions.Timer((minutes) => Timer.Start(minutes)),
            SystemActions.KillAhkProcesses((*) => KillAllAHkProcesses(true))
        ], "Age of Efficiency")
    }
}
