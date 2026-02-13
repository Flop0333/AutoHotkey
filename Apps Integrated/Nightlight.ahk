; ============================================================================
; === Nightlight - Screen overlay to reduce blue light ========================
; ============================================================================

A_MaxHotkeysPerInterval := 100

ShowNightLight() => NightLight.Show()
SetNightLight(amount) => NightLight.Set(amount)
DimNightLight() => NightLight.Dim()
BrightenNightLight() => NightLight.Brighten()


class NightLight {
    
    static transparency := 65 ; value between 0-255
    static overlay_color := '352111'

    static __New() {
        ; Setup Overlay
        this.overlay := Gui('+AlwaysOnTop +ToolWindow -Caption -DPIScale +E0x20')
        this.overlay.BackColor := this.overlay_color
        this.overlay.Show('x' SysGet(76) ' y' SysGet(77) ' w' SysGet(78) ' h' SysGet(79) ' NoActivate Hide')
        WinSetTransparent(this.transparency, this.overlay.Hwnd)

        ; Tray := WinExist("ahk_class Shell_TrayWnd")
        ; this.sliderGui := Gui("+AlwaysOnTop +ToolWindow -DPIScale +E0x20 -caption +Owner" Tray)
        this.sliderGui := Gui("+AlwaysOnTop +ToolWindow -DPIScale +E0x20 -caption")
        this.sliderGui.BackColor := "0x1e1e1e"
        this.sliderGui.SetFont("cwhite s24")
        this.sliderGui.AddText("x50 y0", "Brightness")
        this.slider := this.sliderGui.AddSlider("x0 y5 w300", this.transparency)
        this.slider.Value := 100
        this.slider.BackColor := ("0x0e0e0e")
        WinSetTransparent(200, this.slider)
        this.slider.OnEvent("Change", (*) => this._OnSliderChange())
    }

    static Show() => "" ; this.sliderGui.Show("x160 w600 y" A_ScreenHeight - 52)

    static Toggle_NightLight() => (WinExist('ahk_id ' this.overlay.Hwnd) ? this.overlay.Hide() : this.overlay.Restore())

    static Set(amount) {
        this.slider.Value := amount
        this._OnSliderChange()
    }

    static Dim(amount := 1) {
        this.slider.Value -= amount
        this._OnSliderChange()
    }
    static Brighten(amount := 1) {
        this.slider.Value += amount
        this._OnSliderChange()
    }

    static _OnSliderChange() {
        this.transparency := 100 - this.slider.Value ; Reverse
        this.overlay.Restore()
        this.overlay.BackColor := this.overlay_color
        WinSetTransparent(this.transparency, this.overlay.Hwnd)
    }
}