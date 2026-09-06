; ============================================================================
; Text Speaker - Text to Speech Application
; ============================================================================
;
; [FEATURES]
;   - Toggle text-to-speech playback with Ctrl + Space (pauses/resumes in place)
;   - Reads selected text aloud, preferring higher-quality installed voices
;   - Always-on-top cassette-player control panel: Play/Pause, Restart, Volume, Speed
;   - Adjust volume with Up/Down arrow keys during playback
;   - Adjust speech speed with Left/Right arrow keys during playback
;   - Last-used voice/volume/speed persist across restarts
; ============================================================================

#Include ..\..\Lib\Core.ahk
#Include ..\..\Lib\Tools\WebView\WebViewToo.ahk

^Space::TextSpeaker.TogglePlay()

class TextSpeaker {

    static _spVoice := ComObject("SAPI.SpVoice")
    static _appDir := Paths.appsStandalone "\Text Speaker"
    static _uiPath := this._appDir "\User Interface"
    static _settingsPath := this._appDir "\Text Speaker.settings.json"

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
    ; Play-vs-Pause-vs-Resume from it  .

    static TogglePlay() {
        try {
            switch this._state {
                case "speaking": this.Pause()
                case "paused": this.Resume()
                default: this.Speak()
            }
        } catch as Error {
            Info("Error in TogglePlay: " Error.Message " at line " Error.Line)
        }
        this._SetupHotkeys()
    }

    static Speak(text := "", voice := "") {
        if text = "" {
            try {
                text := this._GetSelectedText()
            } catch as Error {
                Info("Error getting selected text: " Error.Message)
                return
            }
        }
        if voice = ""
            voice := this._currentVoice
        if voice = "" {
            voice := this.defaultVoice
            if voice = "" {
                MsgBox("No voice found", "Error", "Iconi T1")
                return
            }
        }
        if !text
            return

        try {
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
        } catch as Error {
            Info("Error in Speak: " Error.Message " at line " Error.Line)
        }
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
        this._HidePanel()
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
        volume := Max(0, Min(100, Round(volume)))
        this._currentVolume := volume
        try this._spVoice.Volume := volume
        this._SaveSettings()
        this._PushPanelState()
        DarkToolTip("Volume: " volume)
    }

    static _SpeedUp() {
        this._SetSpeedIndex(this._speedIndex + 1)
    }

    static _SpeedDown() {
        this._SetSpeedIndex(this._speedIndex - 1)
    }

    static _SetSpeedIndex(index) {
        index := Max(0, Min(this.speedOptions.Length - 1, Round(index)))
        this._speedIndex := index
        try this._spVoice.Rate := this.speedOptions[index + 1].rate
        this._SaveSettings()
        this._PushPanelState()
        DarkToolTip("Speed: " this.speedOptions[index + 1].label)
    }

    static _GetSelectedText() {
        backupClipboard := A_Clipboard
        backupWindow := WinExist("A") ; Speaking is triggered from whatever window has the selection
        A_Clipboard := ""
        try Send("^c")
        Sleep(100) ; Give the target app time to fill the clipboard
        highlightedText := A_Clipboard
        A_Clipboard := backupClipboard
        if backupWindow
            WinActivate(backupWindow) ; Restore focus, since copying can steal it
        return highlightedText
    }

    ; ---- Control panel (WebView cassette player) ---------------------------

    static _ShowPanel() {
        try {
            if !this._panel
                this._panel := TextSpeakerPanel()
            this._panel.ShowPanel()
        } catch {
            ; The panel's underlying window may have been destroyed out from under us
            ; (e.g. Alt+F4 slipping past the Close handler) - rebuild it once and retry.
            this._panel := TextSpeakerPanel()
            this._panel.ShowPanel()
        }
        this._PushPanelState()
        SetTimer(this._pollCallback, 200)
    }

    static _HidePanel() {
        try {
            if this._panel {
                this._panel.Opt("-AlwaysOnTop")
                this._panel.Hide()
            }
        } catch as Error {
            Info("Error hiding panel: " Error.Message)
        }
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
        this._PushPanelState()
    }

    static _SetupHotkeys(onOff := "") {
        if onOff = ""
            onOff := (this._state != "idle") ? "On" : "Off"
        Hotkey("Up", (*) => this._VolumeUp(), onOff)
        Hotkey("Down", (*) => this._VolumeDown(), onOff)
        Hotkey("Left", (*) => this._SpeedDown(), onOff)
        Hotkey("Right", (*) => this._SpeedUp(), onOff)
    }

    static _PushPanelState() {
        if this._panel
            try this._panel.PushState()
    }

    static _GetStateJSON() {
        return JSON.stringify(Map(
            "state", this._state,
            "volume", this._currentVolume,
            "speedIndex", this._speedIndex,
            "speedLabel", this.speedOptions[this._speedIndex + 1].label,
            "speedOptions", this.speedOptions
        ))
    }
}

; A retro cassette-deck styled control panel, rendered as HTML/CSS/JS in a WebView2
; window. The AHK side owns all playback state; this class just mirrors it to the page
; and relays button clicks back.
class TextSpeakerPanel extends WebViewToo {

    __New() {
        super.__New()
        this.SetVirtualHostNameToFolderMapping("textspeaker.local", TextSpeaker._uiPath, 0)
        this.Load("http://textspeaker.local/index.html")

        this.AddCallbackToScript("TogglePlay", (*) => TextSpeaker.TogglePlay())
        this.AddCallbackToScript("Restart", (*) => TextSpeaker.Restart())
        this.AddCallbackToScript("StopSpeaking", (*) => TextSpeaker.Stop())
        this.AddCallbackToScript("SetVolume", (wv, volume) => TextSpeaker._SetVolume(volume))
        this.AddCallbackToScript("SetSpeedIndex", (wv, index) => TextSpeaker._SetSpeedIndex(index))
        this.AddCallbackToScript("GetState", (*) => TextSpeaker._GetStateJSON())

        ; Registering a Close handler suppresses AHK's default destroy-on-close, so an
        ; Alt+F4 (or anything else that slips past the in-page Close button) just hides
        ; the window instead of tearing down the WebView instance.
        this.Gui.OnEvent("Close", (*) => TextSpeaker.Stop())
    }

    ShowPanel() {
     this.Show("w420 h520 y80", "Text Speaker")
     this.Opt("+AlwaysOnTop")
    }

    PushState() => this.ExecuteScript("window.onAhkState && window.onAhkState(" TextSpeaker._GetStateJSON() ")")
}
