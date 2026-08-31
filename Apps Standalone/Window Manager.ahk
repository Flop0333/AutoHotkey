; ============================================================================
; === Window Manager - Intuitive window manipulation =========================
; ============================================================================
;
; [FEATURES]
; - Drag windows from anywhere (not just title bar)
; - Intelligent resize from any quadrant of the window
; - Quick close window under cursor
; - Toggle always-on-top for any window
; - VM-aware: prevents interference with virtual machine windows
;
; [HOTKEYS]
; - Capslock + Left Mouse: Drag window from any position
; - Capslock + Right Mouse: Resize window (direction based on cursor quadrant)
; - Capslock + Middle Mouse: Close window under cursor
; - Capslock + Up Arrow: Toggle always-on-top for active window
;
; Note: Requires Capslock Service to be running
; ============================================================================

#Include ..\Lib\Core.ahk
#Include ..\Lib\Actions\Modules\Window Actions.ahk
SetWinDelay(0)
CoordMode("Mouse")

ActionRegistry.RegisterAll([
    WindowActions.DragUnderMouse(DragWindow),
    WindowActions.ResizeUnderMouse(ResizeWindow),
    WindowActions.CloseUnderMouse((*) => WinClose(Win.WinUnderMouse())),
    WindowActions.ToggleAlwaysOnTop((*) => Win.ToggleAlwaysOnTop())
], "Window Manager")

CapsLock.Hotkey("LButton", ActionBinding.Callback("window.drag-under-mouse", "window-hotkeys"))
CapsLock.Hotkey("RButton", ActionBinding.Callback("window.resize-under-mouse", "window-hotkeys"))
CapsLock.Hotkey("MButton", ActionBinding.Callback("window.close-under-mouse", "window-hotkeys"))
CapsLock.Hotkey("Up", ActionBinding.Callback("window.always-on-top.toggle", "window-hotkeys"))

DragWindow() {
    MouseGetPos(&origionalMouseX, &origionalMouseY, &winId)
    WinGetPos(&currentWinX, &currentWinY,,,winId)

    Loop {
        If !GetKeyState("LButton", "P") || Win.CurrentWindowIsVirtualMachine(winId)
            break

        MouseGetPos(&newMouseX, &newMouseY) 
        newMouseX -= origionalMouseX 
        newMouseY -= origionalMouseY
        newWinX := (currentWinX + newMouseX) 
        newWinY := (currentWinY + newMouseY)
        WinMove(newWinX, newWinY,,,winId) 
    }
    try WinActivate(winId)
}

ResizeWindow() {
    MouseGetPos(&initialMouseX, &initialMouseY, &winId)
    WinGetPos(&WinX, &WinY, &WinW, &WinH, winId)

    ; Determine which quadrant of the window the mouse is in
    ; winLeft:  1 = left half,  -1 = right half
    ; winUp:    1 = top half,   -1 = bottom half
    ; This determines which edges will be resized when dragging
    winLeft := (initialMouseX < WinX + WinW / 2) ? 1 : -1
    winUp := (initialMouseY < WinY + WinH / 2) ? 1 : -1

    previousMouseX := initialMouseX
    previousMouseY := initialMouseY

    Loop {
        if !GetKeyState("RButton", "P") || Win.CurrentWindowIsVirtualMachine(winId)
            break

        MouseGetPos(&currentMouseX, &currentMouseY)
        WinGetPos(&currentWinX, &currentWinY, &currentWinW, &currentWinH, winId)

        ; Calculate mouse movement since last iteration
        offsetX := currentMouseX - previousMouseX
        offsetY := currentMouseY - previousMouseY

        ; Resize logic:
        ; - If mouse is in left/top half: move the window position AND adjust size
        ; - If mouse is in right/bottom half: only adjust size (anchor top-left corner)
        ; Formula: (winLeft + 1) / 2 yields 1 for left, 0 for right (controls position adjustment)
        ;          -winLeft yields -1 for left, 1 for right (controls size adjustment direction)
        WinMove(currentWinX + (winLeft + 1) / 2 * offsetX, 
                currentWinY + (winUp + 1) / 2 * offsetY, 
                currentWinW - winLeft * offsetX, 
                currentWinH - winUp * offsetY, 
                winId)

        previousMouseX := currentMouseX
        previousMouseY := currentMouseY
    }
    try WinActivate(winId)
}
