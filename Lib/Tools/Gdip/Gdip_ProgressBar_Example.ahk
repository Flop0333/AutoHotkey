#Include Gdip_Toolbox.ahk

; Example: Gdip Progress Bar in AHK v2
; This script creates a custom progress bar using Gdip and updates it in a loop.

class GdipProgressBar {
    __New(x, y, w, h, colorBg := 0xFF222222, colorFg := 0xFF00AAFF, alpha := 1) {
        this.x := x, this.y := y, this.w := w, this.h := h
        this.colorBg := colorBg, this.colorFg := colorFg, this.alpha := alpha
        this.value := 0
        this.max := 100
        this.gui := Gui("-Caption +E0x80000 +AlwaysOnTop +ToolWindow +OwnDialogs")
        this.gui.Show("NA")
        this.Update(0)
    }
    SetValue(val) {
        this.value := Clamp(val, 0, this.max)
        this.Update(this.value)
    }
    SetMax(max) {
        this.max := max
        this.Update(this.value)
    }
    Update(val) {
        pToken := Gdip_Startup()
        hdc := CreateCompatibleDC()
        hbm := CreateDIBSection(this.w, this.h, hdc)
        obm := SelectObject(hdc, hbm)
        G := Gdip_GraphicsFromHDC(hdc)
        ; Draw background
        pBrushBg := Gdip_BrushCreateSolid(this.colorBg)
        Gdip_FillRectangle(G, pBrushBg, 0, 0, this.w, this.h)
        Gdip_DeleteBrush(pBrushBg)
        ; Draw foreground (progress)
        percent := this.value / this.max
        fillW := Round(this.w * percent)
        if (fillW > 0) {
            pBrushFg := Gdip_BrushCreateSolid(this.colorFg)
            Gdip_FillRectangle(G, pBrushFg, 0, 0, fillW, this.h)
            Gdip_DeleteBrush(pBrushFg)
        }
        UpdateLayeredWindow(this.gui.hwnd, hdc, this.x, this.y, this.w, this.h)
        SelectObject(hdc, obm)
        DeleteObject(hbm)
        DeleteDC(hdc)
        Gdip_DeleteGraphics(G)
        Gdip_Shutdown(pToken)
    }
    Destroy() {
        this.gui.Destroy()
    }
}

; Usage Example
bar := GdipProgressBar(400, 400, 400, 40)
bar.SetMax(100)

Loop 101 {
    bar.SetValue(A_Index - 1)
    Sleep 30
}

MsgBox("Done! Progress bar will close.")
bar.Destroy()

; Helper function for clamping values
Clamp(val, min, max) {
    return val < min ? min : val > max ? max : val
}
