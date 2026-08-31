#Requires AutoHotkey v2

/** Canonical definitions for reusable productivity, writing, and media actions. */
class ProductivityActions {
    static Timer(execute) => Action("productivity.timer.start", "Timer", execute, {
        description: "Start a focus timer for a number of minutes", category: "Productivity", icon: "Timer",
        argument: ActionArgument.Required("Enter the timer length in minutes")
    })
    static FakeWorkStart(execute) => Action("productivity.fake-work-mode.start", "Fake Work Mode", execute, {
        description: "Prevent the computer from becoming idle", category: "Productivity", icon: "Beer", aliases: ["fake work"]
    })
    static FakeWorkToggle(execute, getState) => Action("productivity.fake-work-mode.toggle", "Fake Work Mode", execute, {
        description: "Enable or disable idle prevention", category: "Productivity", icon: "ai.gif", getState: getState
    })
    static SpellCheckerToggle(execute, getState) => Action("writing.spell-checker.toggle", "Spell Checker", execute, {
        description: "Enable or disable automatic spelling corrections", category: "Writing", icon: "spell checker.gif", getState: getState
    })
    static PictureInPicture(execute) => Action("media.picture-in-picture.start", "Picture in Picture", execute, {
        description: "Move the active browser video into picture-in-picture mode", category: "Media", icon: "Youtube"
    })
    static ScreenOcr(execute) => Action("productivity.screen-ocr.capture", "Capture Text from Screen", execute, {
        description: "Select a screen region and copy recognized text", category: "Productivity", icon: "OCR"
    })
    static ScreenSnipAndCopy(execute) => Action("productivity.screen-snip.copy", "Snip and Copy", execute, {
        description: "Select a screen region, show the snip, and copy it", category: "Productivity"
    })
    static ScreenCopyOnly(execute) => Action("productivity.screen-snip.copy-only", "Copy Screen Region", execute, {
        description: "Select a screen region and copy it without showing a snip", category: "Productivity"
    })
    static ScreenSaveOnly(execute) => Action("productivity.screen-snip.save", "Save Screen Region", execute, {
        description: "Select a screen region and save it to the configured location", category: "Productivity"
    })
}
