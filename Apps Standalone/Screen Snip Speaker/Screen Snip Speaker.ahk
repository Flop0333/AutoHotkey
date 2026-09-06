; ============================================================================
; Screen Snip Speaker - Drag-select any part of the screen, hear it read aloud
; ============================================================================
;
; [FEATURES]
;   - Ctrl + Shift + drag (left mouse button) to select a screen region
;   - The selected region is OCR'd and spoken aloud
;   - The word currently being spoken is highlighted directly on screen
;   - Ctrl + Shift + Escape stops playback and clears the highlight
; ============================================================================

#Requires AutoHotkey v2
#SingleInstance force

#Include ..\..\Lib\Core.ahk
#Include ..\..\Lib\Tools\OCR\lib\OCR.ahk

^+LButton::ScreenSnipSpeaker.StartFromDrag()
^+Escape::ScreenSnipSpeaker.Stop()

class ScreenSnipSpeaker {

    static _spVoice := ComObject("SAPI.SpVoice")
    static _words := []
    static _currentWord := ""

    ; SVEEndInputStream (1) | SVEStartInputStream (2) | SVEWordBoundary (16)
    static __New() {
        this._spVoice.EventInterests := 19
        ComObjConnect(this._spVoice, "ScreenSnipSpeaker_SAPI_")
    }

    static StartFromDrag() {
        area := this._SelectDragRegion("LButton")
        if area.W < 8 || area.H < 8
            return
        this.Start(area)
    }

    static Start(area) {
        this.Stop()

        try {
            result := OCR.FromRect(area.X, area.Y, area.W, area.H, {scale: 2})
        } catch as e {
            Info("OCR failed: " e.Message)
            return
        }

        this._words := this._OrderWordsAndBuildText(result, &text)
        if !this._words.Length {
            Info("No text found in selection")
            return
        }

        this._spVoice.Speak("", 2) ; cancel anything currently speaking
        this._spVoice.Speak(text, 1) ; asynchronous
    }

    static Stop() {
        try this._spVoice.Speak("", 2)
        this._ClearCurrentHighlight()
        this._words := []
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

    ; ---- Word-boundary highlighting -------------------------------------

    static _OnWord(characterPosition, length) {
        this._ClearCurrentHighlight()
        for word in this._words {
            if characterPosition >= word.charStart && characterPosition < word.charEnd {
                this._currentWord := word
                try word.Highlight(0, "Red", 3)
                break
            }
        }
    }

    static _OnEnd() {
        this._ClearCurrentHighlight()
    }

    static _ClearCurrentHighlight() {
        if this._currentWord
            try this._currentWord.Highlight("clear")
        this._currentWord := ""
        try OCR.ClearAllHighlights()
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

; ---- SAPI event sink (ComObjConnect dispatches SpVoiceEvents by name) -----

ScreenSnipSpeaker_SAPI_Word(voice, streamNumber, streamPosition, characterPosition, length) {
    ScreenSnipSpeaker._OnWord(characterPosition, length)
}

ScreenSnipSpeaker_SAPI_EndStream(voice, streamNumber, streamPosition) {
    ScreenSnipSpeaker._OnEnd()
}
