; ============================================================================
; Text Speaker - Text to Speech Application
; ============================================================================
;
; [FEATURES]
;   - Toggle play/pause with Ctrl + Space; reads selected text aloud
;   - Restart the current text from the beginning with Ctrl + Shift + Space
;   - Speaks through the bundled Piper voice (Lib/Tools/Piper) - synthesizes
;     to a WAV file, played back through Windows Media Player's ActiveX
;     control so Play/Pause/Restart/Volume/Speed all stay live and instant
;   - Shows an always-on-top control panel while speaking: Play/Pause,
;     Restart, Volume, and Speed - draggable by its background
;   - Adjust volume with Up/Down and speed with Left/Right while active
;   - Remembers the last-used volume and speed across sessions
; ============================================================================

#Include ..\Lib\Core.ahk
#Include ..\Lib\Tools\Piper\Piper Synthesizer.ahk

^Space::TextSpeaker.TogglePlay()
^+Space::TextSpeaker.Restart()

class TextSpeaker {

    static SETTINGS_FILE_PATH := Paths.autohotkey "\Apps Standalone\Text Speaker.settings.json"

    static _VOLUME_MIN := 0
    static _VOLUME_MAX := 100
    static _SPEED_MIN := 0
    static _SPEED_MAX := 10

    static _defaultVolume := 100
    static _defaultSpeed := 5 ; 5 = normal (1.0x) playback rate - see _SpeedToRate
    static _lastText := ""

    static _player := "" ; WMP ActiveX COM object, created on first use
    static _currentWavPath := ""

    static _panel := ""
    static _playPauseBtn := ""
    static _volumeSlider := ""
    static _speedSlider := ""
    static _watcherFn := ""
    static _dragHandlerRegistered := false

    ; Which backend produced the currently-loaded audio: "piper" or "sapi".
    ; Piper is preferred; SAPI is a fallback for when the bundled engine or
    ; voice model is missing (see Speak()).
    static _engine := ""
    static _sapiPaused := false

    static _voice := ""
    static _spVoice := ComObject("SAPI.SpVoice")
    static voices := this._BuildVoiceList()
    static _settingsLoaded := this._LoadAndApplySettings()
    ; Starts loading Piper's voice model in the background now, so it's
    ; already warm by the time the user first presses Ctrl+Space - loading it
    ; fresh per Speak() call was the main source of noticeable delay.
    static _piperWarmedUp := PiperSynthesizer.WarmUp()

    ; ---- Playback -----------------------------------------------------------

    static TogglePlay() {
        if this._IsPaused()
            this.Resume()
        else if this._IsSpeaking()
            this.Pause()
        else
            this.Speak()
    }

    static Speak(text := this._GetSelectedText()) {
        if !text
            return

        this.Stop()
        if PiperSynthesizer.IsAvailable()
            this._SpeakViaPiper(text)
        else
            this._SpeakViaSapi(text)
    }

    static _SpeakViaPiper(text) {
        wavPath := PiperSynthesizer.Synthesize(text)
        if !wavPath {
            ; Piper looked available but failed at runtime - fall back rather than silently do nothing.
            this._SpeakViaSapi(text)
            return
        }

        this._engine := "piper"
        this._CleanupWav()
        this._lastText := text
        this._currentWavPath := wavPath

        player := this._GetPlayer()
        player.URL := wavPath
        this._WaitUntilPlaying(player)
        try player.settings.volume := this._defaultVolume
        try player.settings.rate := this._SpeedToRate(this._defaultSpeed)

        this._SetupHotkeys("On")
        this._ShowPanel()
    }

    static _SpeakViaSapi(text) {
        voice := this._voice
        if voice = "" {
            voice := this._PickBestVoice()
            if voice = "" {
                MsgBox("No voice found", "Error", "Iconi T1")
                return
            }
        }

        this._engine := "sapi"
        this._sapiPaused := false
        this._voice := voice
        this._lastText := text
        this._spVoice.Voice := voice
        this._spVoice.Volume := this._defaultVolume
        this._spVoice.Rate := this._SapiRateFromSlider(this._defaultSpeed)
        this._spVoice.Speak(text, 1) ; Asynchronous speaking

        this._SetupHotkeys("On")
        this._ShowPanel()
    }

    static Restart() {
        if this._lastText = ""
            return
        if this._engine = "piper" {
            if this._player = ""
                return
            try {
                this._player.controls.currentPosition := 0
                this._player.controls.play()
            }
            this._UpdatePlayPauseLabel()
        } else if this._engine = "sapi" {
            this._SpeakViaSapi(this._lastText)
        }
    }

    static Stop() {
        if this._engine = "piper" {
            if this._player != ""
                try this._player.controls.stop()
        } else if this._engine = "sapi" {
            try this._spVoice.Speak("", 2) ; Purge: cancels the current utterance
            this._sapiPaused := false
        }
        this._SetupHotkeys("Off")
        this._HidePanel()
    }

    static Pause() {
        if this._engine = "piper" {
            if this._player != ""
                try this._player.controls.pause()
        } else if this._engine = "sapi" {
            try this._spVoice.Pause()
            this._sapiPaused := true
        }
        this._SetupHotkeys("On")
        this._UpdatePlayPauseLabel()
    }

    static Resume() {
        if this._engine = "piper" {
            if this._player != ""
                try this._player.controls.play()
        } else if this._engine = "sapi" {
            try this._spVoice.Resume()
            this._sapiPaused := false
        }
        this._SetupHotkeys("On")
        this._UpdatePlayPauseLabel()
    }

    static _IsSpeaking() {
        if this._engine = "piper"
            return this._player != "" && this._PlayState() = 3 ; Playing
        if this._engine = "sapi"
            return !this._sapiPaused && this._spVoice.Status.RunningState = 2
        return false
    }

    static _IsPaused() {
        if this._engine = "piper"
            return this._player != "" && this._PlayState() = 2 ; Paused
        if this._engine = "sapi"
            return this._sapiPaused
        return false
    }

    static _PlayState() {
        try return this._player.playState
        return 0
    }

    static _GetPlayer() {
        if this._player = "" {
            this._player := ComObject("WMPlayer.OCX.7")
            this._player.settings.autoStart := true
            try this._player.uiMode := "none"
        }
        return this._player
    }

    static _WaitUntilPlaying(player, timeoutMs := 2000) {
        elapsed := 0
        while player.playState != 3 && elapsed < timeoutMs {
            Sleep(20)
            elapsed += 20
        }
    }

    static _CleanupWav() {
        if this._currentWavPath != "" {
            try FileDelete(this._currentWavPath)
            this._currentWavPath := ""
        }
    }

    ; ---- Volume / speed -------------------------------------------------

    static _VolumeUp() => this._ApplyVolume(Min(this._VOLUME_MAX, this._defaultVolume + 10))
    static _VolumeDown() => this._ApplyVolume(Max(this._VOLUME_MIN, this._defaultVolume - 10))

    static _ApplyVolume(value) {
        this._defaultVolume := value
        if this._engine = "piper" && this._player != "" {
            try this._player.settings.volume := value
        } else if this._engine = "sapi" {
            try this._spVoice.Volume := value
        }
        if this._volumeSlider != ""
            try this._volumeSlider.Value := value
        DarkToolTip("Volume: " value)
        this._SaveSettings()
    }

    static _SpeedUp() => this._ApplySpeed(Min(this._SPEED_MAX, this._defaultSpeed + 1))
    static _SpeedDown() => this._ApplySpeed(Max(this._SPEED_MIN, this._defaultSpeed - 1))

    static _ApplySpeed(value) {
        this._defaultSpeed := value
        if this._engine = "piper" && this._player != "" {
            try this._player.settings.rate := this._SpeedToRate(value)
        } else if this._engine = "sapi" {
            try this._spVoice.Rate := this._SapiRateFromSlider(value)
        }
        if this._speedSlider != ""
            try this._speedSlider.Value := value
        DarkToolTip("Speed: " value)
        this._SaveSettings()
    }

    ; Maps the 0-10 Speed slider to WMP's playback-rate multiplier, centered
    ; on 5 = 1.0x (normal) - the same "half speed to double speed" convention
    ; video players commonly use, so 0 and 10 stay recognizable, not extreme.
    static _SpeedToRate(sliderValue) {
        if sliderValue <= 5
            return 0.4 + (sliderValue / 5) * 0.6
        return 1.0 + ((sliderValue - 5) / 5) * 1.0
    }

    ; Maps the same 0-10 slider to SAPI's native -10..10 Rate range, centered
    ; on 5 = 0 (normal), matching _SpeedToRate's "5 = normal" convention.
    static _SapiRateFromSlider(sliderValue) => sliderValue - 5

    static _SetupHotkeys(onOff) {
        Hotkey("Up", (*) => this._VolumeUp(), onOff)
        Hotkey("Down", (*) => this._VolumeDown(), onOff)
        Hotkey("Left", (*) => this._SpeedDown(), onOff)
        Hotkey("Right", (*) => this._SpeedUp(), onOff)
    }

    ; ---- SAPI voice selection (currently unused by playback; kept for a
    ; future fallback path if the bundled Piper engine/model are missing) ---

    static _BuildVoiceList() {
        list := []
        try {
            tokens := this._spVoice.GetVoices()
            loop tokens.Count
                list.Push(tokens.Item(A_Index - 1))
        }
        return list
    }

    static _PickBestVoice() {
        for voice in this.voices {
            try if InStr(voice.GetDescription(), "Mobile")
                return voice
        }
        return this.voices.Length ? this.voices[1] : ""
    }

    static _FindVoiceByDescription(description) {
        if description = ""
            return ""
        for voice in this.voices {
            try if voice.GetDescription() = description
                return voice
        }
        return ""
    }

    static _SafeVoiceDescription(voice) {
        if voice = ""
            return ""
        try return voice.GetDescription()
        return ""
    }

    static _DisplayVoiceOptions() {
        for voice in this.voices
            MsgBox(voice.GetDescription())
    }

    ; ---- Settings persistence --------------------------------------------

    static _LoadAndApplySettings() {
        settings := this._ReadSettingsFile()

        savedVoice := this._FindVoiceByDescription(settings.Has("voiceDescription") ? settings["voiceDescription"] : "")
        this._voice := savedVoice != "" ? savedVoice : this._PickBestVoice()

        if settings.Has("speed")
            this._defaultSpeed := settings["speed"]
        if settings.Has("volume")
            this._defaultVolume := settings["volume"]

        try this._spVoice.Volume := this._defaultVolume
        try this._spVoice.Rate := this._defaultSpeed

        return true
    }

    static _ReadSettingsFile() {
        try {
            if FileExist(this.SETTINGS_FILE_PATH) {
                parsed := JSON.parse(FileRead(this.SETTINGS_FILE_PATH, "UTF-8"))
                if Type(parsed) = "Map"
                    return parsed
            }
        }
        return Map()
    }

    static _SaveSettings() {
        settings := Map(
            "voiceDescription", this._SafeVoiceDescription(this._voice),
            "volume", this._defaultVolume,
            "speed", this._defaultSpeed,
            "engine", this._engine != "" ? this._engine : "piper" ; informational only - engine choice is always re-derived from PiperSynthesizer.IsAvailable()
        )

        tempPath := this.SETTINGS_FILE_PATH ".tmp"
        try FileDelete(tempPath)
        try {
            FileAppend(JSON.stringify(settings, unset, "    "), tempPath, "UTF-8-RAW")
            FileMove(tempPath, this.SETTINGS_FILE_PATH, true)
        } catch {
            try FileDelete(tempPath)
        }
    }

    ; ---- Control panel ----------------------------------------------------

    static _EnsurePanel() {
        if this._panel != ""
            return this._panel

        panel := DarkGui("+AlwaysOnTop +ToolWindow -Caption", "Text Speaker")
        panel.MarginX := 14
        panel.MarginY := 12

        playPauseBtn := panel.AddButton("w74", "Pause")
        playPauseBtn.OnEvent("Click", (*) => this.TogglePlay())

        restartBtn := panel.AddButton("x+8 w74", "Restart")
        restartBtn.OnEvent("Click", (*) => this.Restart())

        closeBtn := panel.AddButton("x+8 w60", "Close")
        closeBtn.OnEvent("Click", (*) => this.Stop())

        panel.SetFont("s10 cC5C5C5")
        panel.AddText("xm y+12", "Volume")
        volumeSlider := panel.AddSlider("xm w232 Range" this._VOLUME_MIN "-" this._VOLUME_MAX " ToolTip", this._defaultVolume)
        volumeSlider.OnEvent("Change", (*) => this._ApplyVolume(volumeSlider.Value))

        panel.AddText("xm y+8", "Speed")
        speedSlider := panel.AddSlider("xm w232 Range" this._SPEED_MIN "-" this._SPEED_MAX " ToolTip", this._defaultSpeed)
        speedSlider.OnEvent("Change", (*) => this._ApplySpeed(speedSlider.Value))

        panel.OnEvent("Close", (*) => this.Stop())

        this._panel := panel
        this._playPauseBtn := playPauseBtn
        this._volumeSlider := volumeSlider
        this._speedSlider := speedSlider

        this._EnableDragging(panel)
        return panel
    }

    ; Clicking the panel's background (not a button/slider) drags it, since it has no title bar.
    static _EnableDragging(panel) {
        if this._dragHandlerRegistered
            return
        this._dragHandlerRegistered := true
        panelHwnd := panel.Hwnd
        OnMessage(0x201, (wParam, lParam, msg, hwnd) => (hwnd = panelHwnd ? PostMessage(0xA1, 2, , , hwnd) : 0))
    }

    static _UpdatePlayPauseLabel() {
        if this._playPauseBtn != ""
            this._playPauseBtn.Text := this._IsPaused() ? "Play" : "Pause"
    }

    static _ShowPanel() {
        panel := this._EnsurePanel()
        this._UpdatePlayPauseLabel()
        try this._volumeSlider.Value := this._defaultVolume
        try this._speedSlider.Value := this._defaultSpeed
        panel.Show("x" (A_ScreenWidth - 280) " y" (A_ScreenHeight - 190) " w260 h170 NoActivate")
        WinSetRegion("0-0 w260 h170 r14-14", panel)
        this._StartPanelWatcher()
    }

    static _HidePanel() {
        this._StopPanelWatcher()
        if this._panel != ""
            try this._panel.Hide()
    }

    ; Speech end isn't event-driven here, so poll lightly and auto-hide once it's done.
    static _StartPanelWatcher() {
        this._StopPanelWatcher()
        this._watcherFn := ObjBindMethod(this, "_CheckPanelState")
        SetTimer(this._watcherFn, 300)
    }

    static _StopPanelWatcher() {
        if this._watcherFn != "" {
            SetTimer(this._watcherFn, 0)
            this._watcherFn := ""
        }
    }

    static _CheckPanelState() {
        state := this._PlayState()
        if state = 1 || state = 8 ; Stopped or MediaEnded
            this._HidePanel()
    }

    ; ---- Text capture -------------------------------------------------------

    static _GetSelectedText() {
        backupClipboard := A_Clipboard
        A_Clipboard := ""
        Send("^c")
        Sleep(50)
        highightedText := A_Clipboard
        A_Clipboard := backupClipboard
        return highightedText
    }
}
