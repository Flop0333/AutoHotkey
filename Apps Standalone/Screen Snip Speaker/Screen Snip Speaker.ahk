; ============================================================================
; Screen Snip Speaker - Drag-select any part of the screen, hear it read aloud
; ============================================================================
;
; Meant to be #Include'd from Text Speaker.ahk, which owns the actual SAPI
; voice, playback state, and cassette control panel. This file only turns a
; screen selection into text + word positions and hands them to TextSpeaker.
;
; [FEATURES]
;   - Ctrl + Shift + drag (left mouse button) to select a screen region
;   - The selected region is OCR'd and spoken aloud via TextSpeaker
;   - The word currently being spoken is highlighted directly on screen
;   - Ctrl + Shift + Escape stops playback and clears the highlight
; ============================================================================

#Include ..\..\Lib\Tools\OCR\lib\OCR.ahk

^+LButton::ScreenSnipSpeaker.StartFromDrag()
^+Escape::TextSpeaker.Stop()

class ScreenSnipSpeaker {

    static StartFromDrag() {
        area := this._SelectDragRegion("LButton")
        if area.W < 8 || area.H < 8
            return
        this.Start(area)
    }

    static Start(area) {
        try {
            result := OCR.FromRect(area.X, area.Y, area.W, area.H, {scale: 2})
        } catch as e {
            Info("OCR failed: " e.Message)
            return
        }

        words := this._OrderWordsAndBuildText(result, &text)
        if !words.Length {
            Info("No text found in selection")
            return
        }

        TextSpeaker.Speak(text, "", words)
    }

    ; ---- Reading order & speech text -----------------------------------

    ; UWP OCR groups words into blocks rather than true reading-order lines,
    ; so cluster words into lines ourselves (OCR.Cluster) before speaking -
    ; otherwise both the spoken order and the word-boundary highlighting
    ; would jump around the screen.
    static _OrderWordsAndBuildText(result, &text) {
        lines := OCR.Cluster(result.Words)
        words := []
        text := ""
        for line in lines {
            for index, word in line.Words {
                word.DefineProp("charStart", {value: StrLen(text)})
                text .= word.Text
                word.DefineProp("charEnd", {value: StrLen(text)})
                text .= (index < line.Words.Length) ? " " : ""
                words.Push(word)
            }
            text .= "`n"
        }
        return words
    }

    ; ---- Screen region drag-selection ------------------------------------

    static _SelectDragRegion(key) {
        Try DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")

        guiSSR := Gui("+AlwaysOnTop -Caption +Border +ToolWindow +LastFound -DPIScale", "ScreenSnipSpeakerSelect")
        guiSSR.MarginX := 0, guiSSR.MarginY := 0
        guiSSR.BackColor := "0011ff"
        WinSetTransparent(80, guiSSR)

        CoordMode("Mouse", "Screen")
        MouseGetPos(&startX, &startY)
        guiSSR.Show("NA x" startX " y" startY " w1 h1")

        Loop {
            MouseGetPos(&endX, &endY)
            w := Max(Abs(startX - endX), 1)
            h := Max(Abs(startY - endY), 1)
            x := Min(startX, endX)
            y := Min(startY, endY)
            guiSSR.Move(x, y, w, h)
            Sleep(10)
        } Until !GetKeyState(key, "P")

        guiSSR.GetPos(&x, &y, &w, &h)
        guiSSR.Destroy()
        return {X: x, Y: y, W: w, H: h}
    }
}
