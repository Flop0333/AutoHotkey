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
        this.Width := A_ScreenWidth
        this.Height := A_ScreenHeight
        this.Gui := Gui("-Caption +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs")
        this.Gui.Show("NA")
        this.hwnd := WinExist()
        this.hbm := CreateDIBSection(this.Width, this.Height)
        this.hdc := CreateCompatibleDC()
        this.obm := SelectObject(this.hdc, this.hbm)
        this.G := Gdip_GraphicsFromHDC(this.hdc)
        Gdip_SetSmoothingMode(this.G, 4)
        this.isDrawing := false
        this.lastX := 0
        this.lastY := 0
        this.wasDrawing := false
        this.timer := SetTimer(ObjBindMethod(this, "DrawLoop"), 10)
        OnExit(ObjBindMethod(this, "Cleanup"))
    }

    DrawLoop() {
        if GetKeyState("Shift") && GetKeyState("LButton") {
            MouseGetPos(&mx, &my)
            if !this.isDrawing {
                this.isDrawing := true
                this.lastX := mx
                this.lastY := my
            } else if (mx != this.lastX || my != this.lastY) {
                pPen := Gdip_CreatePen(ScreenDrawer.PenColor, ScreenDrawer.PenWidth)
                Gdip_DrawLine(this.G, pPen, this.lastX, this.lastY, mx, my)
                Gdip_DeletePen(pPen)
                UpdateLayeredWindow(this.hwnd, this.hdc, 0, 0, this.Width, this.Height)
                this.lastX := mx
                this.lastY := my
            }
            this.wasDrawing := true
        } else {
            if this.wasDrawing {
                this.wasDrawing := false
            }
            this.isDrawing := false
        }
    }

    Clear() {
        Gdip_GraphicsClear(this.G)
        UpdateLayeredWindow(this.hwnd, this.hdc, 0, 0, this.Width, this.Height)
    }

    Cleanup(ExitReason := "", ExitCode := 0) {
        try SetTimer(this.timer, 0)
        SelectObject(this.hdc, this.obm)
        DeleteObject(this.hbm)
        DeleteDC(this.hdc)
        Gdip_DeleteGraphics(this.G)
        Gdip_Shutdown(this.pToken)
    }
}

global drawer := ScreenDrawer()

Esc:: drawer.Clear()
