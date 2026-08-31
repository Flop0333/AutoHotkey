#Requires AutoHotkey v2

/** Canonical action definitions for window, monitor, and desktop controls. */
class WindowActions {
    static DragUnderMouse(execute) => Action(ActionIds.Window.DragUnderMouse, "Drag Window", execute, {category: "Window"})
    static ResizeUnderMouse(execute) => Action(ActionIds.Window.ResizeUnderMouse, "Resize Window", execute, {category: "Window"})
    static CloseUnderMouse(execute) => Action(ActionIds.Window.CloseUnderMouse, "Close Window", execute, {category: "Window"})
    static ToggleAlwaysOnTop(execute) => Action(ActionIds.Window.ToggleAlwaysOnTop, "Toggle Always on Top", execute, {category: "Window"})
    static MoveToLeftMonitor(execute) => Action(ActionIds.Window.MoveToLeftMonitor, "Move to Left Monitor", execute, {category: "Window"})
    static MoveToRightMonitor(execute) => Action(ActionIds.Window.MoveToRightMonitor, "Move to Right Monitor", execute, {category: "Window"})
    static MaximizeUnderMouse(execute) => Action(ActionIds.Window.MaximizeUnderMouse, "Maximize Window", execute, {category: "Window"})
    static MinimizeUnderMouse(execute) => Action(ActionIds.Window.MinimizeUnderMouse, "Minimize Window", execute, {category: "Window"})
    static PreviousDesktop(execute) => Action(ActionIds.Desktop.Previous, "Previous Desktop", execute, {category: "Desktop"})
    static TogglePinToDesktops(execute) => Action(ActionIds.Desktop.TogglePinWindow, "Toggle Window on All Desktops", execute, {category: "Desktop"})
}
