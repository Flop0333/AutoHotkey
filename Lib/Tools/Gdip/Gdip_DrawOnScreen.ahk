; Gdip_DrawOnScreen.ahk
; Draw on the screen using Shift + Left Mouse Button
; Press Esc to clear all drawings and exit



#SingleInstance
#Include Gdip_All.ahk

class ScreenDrawer {
    static PenColor := 0xFF0099FF
    static PenWidth := 3

    __New() {
        this.pToken := Gdip_Startup()
        if !this.pToken {
            MsgBox "Gdiplus failed to start. Please ensure you have gdiplus on your system."
            ExitApp()
        }
        this.monitors := []
        count := MonitorGetCount()
        Loop count {
            idx := A_Index
            try {
                MonitorGet idx, &Left, &Top, &Right, &Bottom
            } catch {
                continue
            }
            mon := {}
            mon.X := Left
            mon.Y := Top
            mon.Width := Right - Left
            mon.Height := Bottom - Top
            mon.Gui := Gui("-Caption +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs")
            mon.Gui.Show(Format("NA w{} h{}", mon.Width, mon.Height))
            mon.hwnd := mon.Gui.Hwnd
            mon.hbm := CreateDIBSection(mon.Width, mon.Height)
            mon.hdc := CreateCompatibleDC()
            mon.obm := SelectObject(mon.hdc, mon.hbm)
            mon.G := Gdip_GraphicsFromHDC(mon.hdc)
            Gdip_SetSmoothingMode(mon.G, 4)
            mon.Alpha := 180
            bgBrush := Gdip_BrushCreateSolid(0x80FFCC00)
            Gdip_FillRectangle(mon.G, bgBrush, 0, 0, mon.Width, mon.Height)
            Gdip_DeleteBrush(bgBrush)
            ; Move overlay to correct monitor position after all GDI setup
            UpdateLayeredWindow(mon.hwnd, mon.hdc, 0, 0, mon.Width, mon.Height, mon.Alpha)
            SetImage(mon.hwnd, mon.hbm)
            DllCall("MoveWindow", "ptr", mon.hwnd, "int", mon.X, "int", mon.Y, "int", mon.Width, "int", mon.Height, "int", true)
            this.monitors.Push(mon)
        }
        this.isDrawing := false
        this.lastX := 0
        this.lastY := 0
        this.lastMonitor := 0
        this.wasDrawing := false
        this.timer := SetTimer(ObjBindMethod(this, "DrawLoop"), 10)
        OnExit(ObjBindMethod(this, "Cleanup"))
    }

    GetMonitorAt(x, y) {
        ; Ensure 1-based index for AHK arrays
        for idx, mon in this.monitors {
            if (x >= mon.X && x < mon.X + mon.Width && y >= mon.Y && y < mon.Y + mon.Height) {
                return idx
            }
        }
        return 1 ; fallback to primary
    }

    DrawLoop() {
        if GetKeyState("Shift") && GetKeyState("LButton") {
            MouseGetPos(&mx, &my)
            monIdx := this.GetMonitorAt(mx, my)
            if !this.monitors.Has(monIdx) {
                return
            }
            mon := this.monitors[monIdx]
            relX := mx - mon.X
            relY := my - mon.Y
            if !this.isDrawing || this.lastMonitor != monIdx {
                this.isDrawing := true
                this.lastX := relX
                this.lastY := relY
                this.lastMonitor := monIdx
            } else if (relX != this.lastX || relY != this.lastY) {
                pPen := Gdip_CreatePen(ScreenDrawer.PenColor, ScreenDrawer.PenWidth)
                Gdip_DrawLine(mon.G, pPen, this.lastX, this.lastY, relX, relY)
                Gdip_DeletePen(pPen)
                UpdateLayeredWindow(mon.hwnd, mon.hdc, 0, 0, mon.Width, mon.Height, mon.Alpha)
                SetImage(mon.hwnd, mon.hbm)
                DllCall("MoveWindow", "ptr", mon.hwnd, "int", mon.X, "int", mon.Y, "int", mon.Width, "int", mon.Height, "int", true)
                this.lastX := relX
                this.lastY := relY
            }
            this.wasDrawing := true
        } else {
            this.isDrawing := false
            this.lastMonitor := 0
            if this.wasDrawing {
                this.wasDrawing := false
            }
        }
    }

    Clear() {
        for _, mon in this.monitors {
            Gdip_GraphicsClear(mon.G)
            UpdateLayeredWindow(mon.hwnd, mon.hdc, 0, 0, mon.Width, mon.Height, mon.Alpha)
            SetImage(mon.hwnd, mon.hbm)
        }
    }

    Cleanup(ExitReason := "", ExitCode := 0) {
        try SetTimer(this.timer, 0)
        for _, mon in this.monitors {
            SelectObject(mon.hdc, mon.obm)
            DeleteObject(mon.hbm)
            DeleteDC(mon.hdc)
            Gdip_DeleteGraphics(mon.G)
        }
        Gdip_Shutdown(this.pToken)
    }
}

global drawer := ScreenDrawer()

Esc:: {
    ; For debug: clear all overlays
    for _, mon in drawer.monitors {
        Gdip_GraphicsClear(mon.G)
        UpdateLayeredWindow(mon.hwnd, mon.hdc, 0, 0, mon.Width, mon.Height, mon.Alpha)
    }
}
