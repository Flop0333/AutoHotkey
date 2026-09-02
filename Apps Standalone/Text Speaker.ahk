; ============================================================================
; Text Speaker - Text to Speech Application
; ============================================================================
;
; [FEATURES]
;   - Toggle text-to-speech playback with Ctrl + Space
;   - Reads selected text aloud using SAPI voices
;   - Adjust volume with Up/Down arrow keys during playback
;   - Adjust speech speed with Left/Right arrow keys during playback
; ============================================================================

#Include ..\Lib\Core.ahk

^Space::TextSpeaker.TogglePlay()

class TextSpeaker {

    static _defaultSpeed := 3
    static _spVoice := ComObject("SAPI.SpVoice")
    
    static voices := {
        zira: this._getVoice(0),
        david: this._getVoice(1)
    }

    static _getVoice(voiceNumber := number) {
        try return this._spVoice.GetVoices().Item(voiceNumber)
        return ""
    }

    static TogglePlay() => (this._IsSpeaking() ? this.Stop() : this.Speak()) this._SetupHotkeys()

    static Speak(text := this._GetSelectedText(), voice := this.voices.david) {
        ; Check if voice is available
        if voice = "" {
            voice := this.voices.david
            if voice = "" {
                MsgBox("No voice found", "Error", "Iconi T1")
                return
            }
        }


        this.Stop()
        this._spVoice.Voice := voice
        this._spVoice.Rate := this._defaultSpeed
        if (text) 
            this._spVoice.Speak(text, 1)  ; Ensure asynchronous speaking
        ; MsgBox
    }

    static Stop() => this._spVoice.Speak("", 2)
    static _Pause() => this._spVoice.Pause()
    static _Resume() => this._spVoice.Resume()
    static _SetVoice(newVoice) => this._spVoice.Voice := newVoice

    static _IsSpeaking() => (this._spVoice.Status.RunningState = 2)
    
    static _VolumeUp() { 
        Try this._spVoice.Volume := this._spVoice.Volume + 10
        DarkToolTip("Volume: " this._spVoice.Volume)
    }
    
    static _VolumeDown() {
        Try this._spVoice.Volume := this._spVoice.Volume - 10
        DarkToolTip("Volume: " this._spVoice.Volume)
    }      

    static _SpeedUp() {
        if (this._spVoice.Rate < 8) {
            this._defaultSpeed += 1
            this._spVoice.Rate := this._defaultSpeed
        }
        DarkToolTip("Speed: " this._defaultSpeed)
    } 
    
    static _SpeedDown() {
        if (this._spVoice.Rate > 0) {
            this._defaultSpeed -= 1
            this._spVoice.Rate := this._defaultSpeed
        }
        DarkToolTip("Speed: " this._defaultSpeed)
    }
  
    static _GetSelectedText() {
        backupClipboard := A_Clipboard
        A_Clipboard := ""
        Send("^c")
        Sleep(50)
        highightedText := A_Clipboard
        A_Clipboard := backupClipboard
        return highightedText
    }
    
    static _SetupHotkeys(onOff := "") {
        Sleep(700) ; Wait until speaking starts
        if onOff = ""
            onOff := this._IsSpeaking() ? "On" : "Off"
        Hotkey("Up", (*) => this._VolumeUp(), onOff)
        Hotkey("Down", (*) => this._VolumeDown(), onOff)
        Hotkey("Left", (*) => this._SpeedDown(), onOff)
        Hotkey("Right", (*) => this._SpeedUp(), onOff)
    }

    static _DisplayVoiceOptions() {
        allVoices := this._spVoice.GetVoices()
        for voice in allVoices {
            MsgBox(voice.GetDescription())
        }
    }
}
