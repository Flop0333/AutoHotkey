; ============================================================================
; Text Speaker - Text to Speech Application
; ============================================================================
;
; [FEATURES]
;   - Toggle text-to-speech playback with Ctrl + Space (pauses/resumes in place)
;   - Reads selected text aloud, preferring higher-quality installed voices
;   - Always-on-top control panel: Play/Pause, Restart, Volume, Speed
;   - Adjust volume with Up/Down arrow keys during playback
;   - Adjust speech speed with Left/Right arrow keys during playback
;   - Last-used voice/volume/speed persist across restarts
; ============================================================================

#Include ..\Lib\Core.ahk

^Space::TextSpeaker.TogglePlay()

class TextSpeaker {

    static _spVoice := ComObject("SAPI.SpVoice")
    static _settingsPath := Paths.appsStandalone "\Text Speaker.settings.json"

    ; SAPI Rate is an integer (-10..10). These are the discrete steps offered in the
    ; control panel, approximated against that range.
    static speedOptions := [
        {label: "1x", rate: 0},
        {label: "1.25x", rate: 2},
        {label: "1.5x", rate: 4},
        {label: "1.75x", rate: 6},
        {label: "2x", rate: 8}
    ]

    static _speedIndex := 0
    static _lastText := ""
    static _state := "idle" ; "idle" | "speaking" | "paused" - owned by us, never inferred from SAPI
    static _speechStartTick := 0
    static _panel := ""
    static _panelControls := {}
    static _pollCallback := ""

    static __New() {
        this._LoadVoices()
        this._LoadSettings()
        this._pollCallback := ObjBindMethod(this, "_PollPlaybackState")
    }

    ; ---- Voice selection -------------------------------------------------

    static _LoadVoices() {
        this.voices := []
        try {
            for voice in this._spVoice.GetVoices() {
                description := voice.GetDescription()
                this.voices.Push({token: voice, description: description, isMobile: InStr(description, "Mobile") > 0})
            }
        }
        this.defaultVoice := this._PickBestVoice()
    }

    ; Prefer OneCore "Mobile" voices (better quality) over legacy Desktop ones.
    static _PickBestVoice() {
        for voice in this.voices
            if voice.isMobile
                return voice.token
        return this.voices.Length ? this.voices[1].token : ""
    }

    static _FindVoiceByDescription(description) {
        for voice in this.voices
            if voice.description = description
                return voice.token
        return ""
    }

    ; ---- Settings persistence --------------------------------------------

    static _LoadSettings() {
        this._currentVoice := this.defaultVoice
        this._currentVolume := 100
        this._speedIndex := 0

        if !FileExist(this._settingsPath)
            return

        try {
            settings := JSON.parse(FileRead(this._settingsPath))
            if settings.Has("voiceDescription") {
                foundVoice := this._FindVoiceByDescription(settings["voiceDescription"])
                if foundVoice != ""
                    this._currentVoice := foundVoice
            }
            if settings.Has("volume")
                this._currentVolume := settings["volume"]
            if settings.Has("speedIndex") && settings["speedIndex"] >= 0 && settings["speedIndex"] < this.speedOptions.Length
                this._speedIndex := settings["speedIndex"]
        }
    }

    static _SaveSettings() {
        voiceDescription := ""
        try voiceDescription := this._currentVoice.GetDescription()

        settings := Map(
            "voiceDescription", voiceDescription,
            "volume", this._currentVolume,
            "speedIndex", this._speedIndex
        )

        ; Write to a temp file first and rename over the destination, so a crash mid-write
        ; can never leave the settings file deleted or half-written.
        content := JSON.stringify(settings)
        tempPath := this._settingsPath ".tmp"
        try {
            try FileDelete(tempPath)
            FileAppend(content, tempPath)
            FileMove(tempPath, this._settingsPath, true)
        }
    }

    ; ---- Playback ----------------------------------------------------------
    ;
    ; Playback state is tracked ourselves in `_state` rather than re-derived from
    ; SAPI's Status.RunningState on every keypress: RunningState transitions
    ; asynchronously (a few hundred ms of lag around Speak()/Stop()), so deciding
    ; Play-vs-Pause-vs-Resume from it directly is a race - it can land on the wrong
    ; branch and get stuck "paused" with nothing actually playing and no panel shown.
    ; RunningState is still polled, but only to notice natural end-of-speech.

    static TogglePlay() {
        switch this._state {
            case "speaking": this.Pause()
            case "paused": this.Resume()
            default: this.Speak()
        }
        this._SetupHotkeys()
    }

    static Speak(text := this._GetSelectedText(), voice := this._currentVoice) {
        if voice = "" {
            voice := this.defaultVoice
            if voice = "" {
                MsgBox("No voice found", "Error", "Iconi T1")
                return
            }
        }
        if !text
            return

        this._spVoice.Speak("", 2) ; cancel anything currently speaking
        this._currentVoice := voice
        this._spVoice.Voice := voice
        this._spVoice.Volume := this._currentVolume
        this._spVoice.Rate := this.speedOptions[this._speedIndex + 1].rate
        this._lastText := text
        this._state := "speaking"
        this._speechStartTick := A_TickCount
        this._spVoice.Speak(text, 1) ; asynchronous

        this._ShowPanel()
    }

    static Restart() {
        if this._lastText = ""
            return
        this.Speak(this._lastText, this._currentVoice)
    }

    static Stop() {
        this._spVoice.Speak("", 2)
        this._state := "idle"
        this._HidePanel()
        this._SetupHotkeys()
    }

    static Pause() {
        if this._state != "speaking"
            return
        this._spVoice.Pause()
        this._state := "paused"
        this._ShowPanel()
    }

    static Resume() {
        if this._state != "paused"
            return
        this._spVoice.Resume()
        this._state := "speaking"
        this._speechStartTick := A_TickCount
        this._ShowPanel()
    }

    static _IsSpeaking() => (this._spVoice.Status.RunningState = 2)

    static _VolumeUp() {
        this._SetVolume(this._currentVolume + 10)
    }

    static _VolumeDown() {
        this._SetVolume(this._currentVolume - 10)
    }

    static _SetVolume(volume) {
        volume := Max(0, Min(100, volume))
        this._currentVolume := volume
        try this._spVoice.Volume := volume
        this._SaveSettings()
        this._UpdatePanel()
        DarkToolTip("Volume: " volume)
    }

    static _SpeedUp() {
        this._SetSpeedIndex(this._speedIndex + 1)
    }

    static _SpeedDown() {
        this._SetSpeedIndex(this._speedIndex - 1)
    }

    static _SetSpeedIndex(index) {
        index := Max(0, Min(this.speedOptions.Length - 1, index))
        this._speedIndex := index
        try this._spVoice.Rate := this.speedOptions[index + 1].rate
        this._SaveSettings()
        this._UpdatePanel()
        DarkToolTip("Speed: " this.speedOptions[index + 1].label)
    }

    static _GetSelectedText() {
        backupClipboard := A_Clipboard
        A_Clipboard := ""
        Send("^c")
        Sleep(50)
        highlightedText := A_Clipboard
        A_Clipboard := backupClipboard
        return highlightedText
    }

    static _SetupHotkeys(onOff := "") {
        if onOff = ""
            onOff := (this._state != "idle") ? "On" : "Off"
        Hotkey("Up", (*) => this._VolumeUp(), onOff)
        Hotkey("Down", (*) => this._VolumeDown(), onOff)
        Hotkey("Left", (*) => this._SpeedDown(), onOff)
        Hotkey("Right", (*) => this._SpeedUp(), onOff)
    }

    static _DisplayVoiceOptions() {
        for voice in this.voices
            MsgBox(voice.description)
    }

    ; ---- Control panel -----------------------------------------------------

    static _ShowPanel() {
        if !this._panel {
            this._BuildPanel()
        }
        this._UpdatePanel()
        this._panel.Show("w500 h200 NoActivate")
        SetTimer(this._pollCallback, 200)
    }

    static _HidePanel() {
        if this._panel
            this._panel.Hide()
        SetTimer(this._pollCallback, 0)
    }

    static _PollPlaybackState() {
        ; Only speech we started ourselves ever naturally "finishes"; while paused,
        ; RunningState is not reliable, so skip the finish-check entirely then. A short
        ; grace period after Speak()/Resume() avoids a false finish before SAPI's
        ; RunningState has actually flipped to "speaking".
        if this._state = "speaking" && A_TickCount - this._speechStartTick > 300 && !this._IsSpeaking() {
            this._state := "idle"
            this._HidePanel()
            this._SetupHotkeys()
            return
        }
        this._UpdatePanel()
    }

    static _BuildPanel() {
        panel := DarkGui("+AlwaysOnTop -Caption +ToolWindow", "Text Speaker")
        panel.MarginX := 15, panel.MarginY := 12

        panel.SetFont("s11 bold")
        panel.AddText("w230", "Text Speaker")

        panel.SetFont("s10 norm")
        controls := {}
        controls.playPauseButton := panel.AddButton("w80 y+10", "Pause")
        controls.playPauseButton.OnEvent("Click", (*) => this.TogglePlay())

        controls.restartButton := panel.AddButton("w80 x+10", "Restart")
        controls.restartButton.OnEvent("Click", (*) => this.Restart())

        controls.closeButton := panel.AddButton("w60 x+10", "Close")
        controls.closeButton.OnEvent("Click", (*) => this.Stop())

        controls.volumeLabel := panel.AddText("w230 y+15", "Volume: " this._currentVolume)
        controls.volumeSlider := panel.AddSlider("w230 y+2 Range0-100", this._currentVolume)
        controls.volumeSlider.OnEvent("Change", (ctrl, *) => this._SetVolume(ctrl.Value))

        controls.speedLabel := panel.AddText("w230 y+15", "Speed: " this.speedOptions[this._speedIndex + 1].label)
        speedButtons := []
        x := "y+2"
        for i, option in this.speedOptions {
            btn := panel.AddButton((i = 1 ? x : "x+5") " w42", option.label)
            btn.OnEvent("Click", ObjBindMethod(this, "_SetSpeedIndex", i - 1))
            speedButtons.Push(btn)
        }
        controls.speedButtons := speedButtons

        panel.OnEvent("Close", (*) => this.Stop())

        this._panel := panel
        this._panelControls := controls
    }

    static _UpdatePanel() {
        if !this._panel
            return
        controls := this._panelControls
        controls.playPauseButton.Text := (this._state = "paused") ? "Play" : "Pause"
        controls.volumeLabel.Text := "Volume: " this._currentVolume
        controls.volumeSlider.Value := this._currentVolume
        controls.speedLabel.Text := "Speed: " this.speedOptions[this._speedIndex + 1].label
    }
}
