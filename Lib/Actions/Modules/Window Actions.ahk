#Requires AutoHotkey v2

/** Canonical action definitions for window, monitor, and desktop controls. */
class WindowActions {
    static DragUnderMouse(execute) => Action("window.drag-under-mouse", "Drag Window", execute, {category: "Window"})
    static ResizeUnderMouse(execute) => Action("window.resize-under-mouse", "Resize Window", execute, {category: "Window"})
    static CloseUnderMouse(execute) => Action("window.close-under-mouse", "Close Window", execute, {category: "Window"})
    static ToggleAlwaysOnTop(execute) => Action("window.always-on-top.toggle", "Toggle Always on Top", execute, {category: "Window"})
    static MoveToLeftMonitor(execute) => Action("window.move-to-left-monitor", "Move to Left Monitor", execute, {category: "Window"})
    static MoveToRightMonitor(execute) => Action("window.move-to-right-monitor", "Move to Right Monitor", execute, {category: "Window"})
    static MaximizeUnderMouse(execute) => Action("window.maximize-under-mouse", "Maximize Window", execute, {category: "Window"})
    static MinimizeUnderMouse(execute) => Action("window.minimize-under-mouse", "Minimize Window", execute, {category: "Window"})
    static PreviousDesktop(execute) => Action("desktop.previous", "Previous Desktop", execute, {category: "Desktop"})
    static TogglePinToDesktops(execute) => Action("desktop.pin-window.toggle", "Toggle Window on All Desktops", execute, {category: "Desktop"})
}
