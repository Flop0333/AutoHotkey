; Tracks only a GUI's restored position and dimensions. Minimized and maximized
; bounds are deliberately ignored so they cannot replace the useful windowed
; state in the application's settings file.
class WindowPositionTracker {
    static WM_MOVE := 0x0003
    static WM_SIZE := 0x0005
    static SIZE_RESTORED := 0
    static DEBOUNCE_INTERVAL := 1000

    __New(gui, settingsService) {
        this.gui := gui
        this.settingsService := settingsService
        this.saveTimer := ObjBindMethod(this, "SaveSettings")
        this.moveHandler := ObjBindMethod(this, "HandleMove")
        this.sizeHandler := ObjBindMethod(this, "HandleSize")
        OnMessage(WindowPositionTracker.WM_MOVE, this.moveHandler)
        OnMessage(WindowPositionTracker.WM_SIZE, this.sizeHandler)
    }

    HandleMove(wParam, lParam, msg, hwnd) {
        if (hwnd = this.gui.Hwnd)
            this.ScheduleSave()
    }

    HandleSize(wParam, lParam, msg, hwnd) {
        if (hwnd = this.gui.Hwnd
            && wParam = WindowPositionTracker.SIZE_RESTORED)
            this.ScheduleSave()
    }

    ScheduleSave() {
        SetTimer(this.saveTimer, -WindowPositionTracker.DEBOUNCE_INTERVAL)
    }

    SaveSettings() {
        try windowState := WinGetMinMax("ahk_id " this.gui.Hwnd)
        catch
            return
        if (windowState != 0)
            return

        this.gui.GetPos(&x, &y, &width, &height)
        if (width <= 0 || height <= 0 || !this.IsOnAnyMonitor(x, y, width, height))
            return

        this.settingsService.Window.Width := width
        this.settingsService.Window.Height := height
        this.settingsService.Window.x := x
        this.settingsService.Window.y := y
        this.settingsService.SaveFile()
    }

    IsOnAnyMonitor(x, y, width, height) {
        loop MonitorGetCount() {
            MonitorGetWorkArea(A_Index, &left, &top, &right, &bottom)
            if (x < right && x + width > left && y < bottom && y + height > top)
                return true
        }
        return false
    }
}
