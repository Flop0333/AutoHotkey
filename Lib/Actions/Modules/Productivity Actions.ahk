#Requires AutoHotkey v2

/**
 * Canonical metadata factories for reusable productivity, writing, and media actions.
 * execute changes behavior; getState is supplied only for toggle-style actions.
 */
class ProductivityActions {
    static Timer(execute) => Action(ActionIds.Productivity.TimerStart, "Timer", execute, {
        description: "Start a focus timer for a number of minutes", category: "Productivity", icon: "Timer",
        argument: ActionArgument.Required("Enter the timer length in minutes")
    })
    static FakeWorkStart(execute) => Action(ActionIds.Productivity.FakeWorkStart, "Fake Work Mode", execute, {
        description: "Prevent the computer from becoming idle", category: "Productivity", icon: "Beer", aliases: ["fake work"]
    })
    static FakeWorkToggle(execute, getState) => Action(ActionIds.Productivity.FakeWorkToggle, "Fake Work Mode", execute, {
        description: "Enable or disable idle prevention", category: "Productivity", icon: "ai.gif", getState: getState
    })
    static SpellCheckerToggle(execute, getState) => Action(ActionIds.Writing.SpellCheckerToggle, "Spell Checker", execute, {
        description: "Enable or disable automatic spelling corrections", category: "Writing", icon: "spell checker.gif", getState: getState
    })
    static PictureInPicture(execute) => Action(ActionIds.Media.PictureInPictureStart, "Picture in Picture", execute, {
        description: "Move the active browser video into picture-in-picture mode", category: "Media", icon: "Youtube"
    })
    static ScreenOcr(execute) => Action(ActionIds.Productivity.ScreenOcrCapture, "Capture Text from Screen", execute, {
        description: "Select a screen region and copy recognized text", category: "Productivity", icon: "OCR"
    })
    static ScreenSnipAndCopy(execute) => Action(ActionIds.Productivity.ScreenSnipCopy, "Snip and Copy", execute, {
        description: "Select a screen region, show the snip, and copy it", category: "Productivity"
    })
    static ScreenCopyOnly(execute) => Action(ActionIds.Productivity.ScreenSnipCopyOnly, "Copy Screen Region", execute, {
        description: "Select a screen region and copy it without showing a snip", category: "Productivity"
    })
    static ScreenSaveOnly(execute) => Action(ActionIds.Productivity.ScreenSnipSave, "Save Screen Region", execute, {
        description: "Select a screen region and save it to the configured location", category: "Productivity"
    })
}
