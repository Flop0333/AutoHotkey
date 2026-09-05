; ============================================================================
; Text Speaker - Text to Speech Application
; ============================================================================
;
; [FEATURES]
;   - Toggle play/pause with Ctrl + Space; reads selected text aloud
;   - Restart the current text from the beginning with Ctrl + Shift + Space
;   - Prefers the best-sounding installed voice automatically (Windows'
;     higher-quality "Mobile"/OneCore voices over legacy Desktop ones)
;   - Shows an always-on-top control panel while speaking: Play/Pause,
;     Restart, Volume, and Speed - draggable by its background
;   - Adjust volume with Up/Down and speed with Left/Right while active
;   - Remembers the last-used voice, volume, and speed across sessions
; ============================================================================

#Include ..\Lib\Core.ahk

^Space::TextSpeaker.TogglePlay()
^+Space::TextSpeaker.Restart()

class TextSpeaker {

    static SETTINGS_FILE_PATH := Paths.autohotkey "\Apps Standalone\Text Speaker.settings.json"

    static _VOLUME_MIN := 0
    static _VOLUME_MAX := 100
    static _SPEED_MIN := 0
    static _SPEED_MAX := 10

    static _defaultVolume := 100
    static _defaultSpeed := 3
    static _lastText := ""
    static _isPaused := false
    static _voice := ""

    static _panel := ""
    static _playPauseBtn := ""
    static _volumeSlider := ""
    static _speedSlider := ""
    static _watcherFn := ""
    static _dragHandlerRegistered := false

    ; _spVoice must exist before voices/settings are resolved from it.
    static _spVoice := ComObject("SAPI.SpVoice")
    static voices := this._BuildVoiceList()
    static _settingsLoaded := this._LoadAndApplySettings()

    ; ---- Playback -----------------------------------------------------------

    static TogglePlay() {
        if this._isPaused
            this.Resume()
        else if this._IsSpeaking()
            this.Pause()
        else
            this.Speak()
    }

    static Speak(text := this._GetSelectedText(), voice := this._voice) {
        if voice = "" {
            voice := this._PickBestVoice()
            if voice = "" {
                MsgBox("No voice found", "Error", "Iconi T1")
                return
            }
        }

        this.Stop()
        if !(text)
            return

        this._voice := voice
        this._spVoice.Voice := voice
        this._spVoice.Rate := this._defaultSpeed
        this._isPaused := false
        this._lastText := text
        this._spVoice.Speak(text, 1) ; Asynchronous speaking

        this._SetupHotkeys("On")
        this._ShowPanel()
    }

    static Restart() {
        if this._lastText = ""
            return
        this.Speak(this._lastText, this._voice)
    }

    static Stop() {
        this._spVoice.Speak("", 2) ; Purge: cancels the current utterance
        this._isPaused := false
        this._SetupHotkeys("Off")
        this._HidePanel()
    }

    static Pause() {
        this._spVoice.Pause()
        this._isPaused := true
        this._SetupHotkeys("On")
        this._UpdatePlayPauseLabel()
    }

    static Resume() {
        this._spVoice.Resume()
        this._isPaused := false
        this._SetupHotkeys("On")
        this._UpdatePlayPauseLabel()
    }

    static _IsSpeaking() => (this._spVoice.Status.RunningState = 2)

    ; ---- Volume / speed -------------------------------------------------

    static _VolumeUp() => this._ApplyVolume(Min(this._VOLUME_MAX, this._spVoice.Volume + 10))
    static _VolumeDown() => this._ApplyVolume(Max(this._VOLUME_MIN, this._spVoice.Volume - 10))

    static _ApplyVolume(value) {
        try this._spVoice.Volume := value
        if this._volumeSlider != ""
            try this._volumeSlider.Value := value
        DarkToolTip("Volume: " value)
        this._SaveSettings()
    }

    static _SpeedUp() => this._ApplySpeed(Min(this._SPEED_MAX, this._defaultSpeed + 1))
    static _SpeedDown() => this._ApplySpeed(Max(this._SPEED_MIN, this._defaultSpeed - 1))

    static _ApplySpeed(value) {
        this._defaultSpeed := value
        try this._spVoice.Rate := value
        if this._speedSlider != ""
            try this._speedSlider.Value := value
        DarkToolTip("Speed: " value)
        this._SaveSettings()
    }

    static _SetupHotkeys(onOff) {
        Hotkey("Up", (*) => this._VolumeUp(), onOff)
        Hotkey("Down", (*) => this._VolumeDown(), onOff)
        Hotkey("Left", (*) => this._SpeedDown(), onOff)
        Hotkey("Right", (*) => this._SpeedUp(), onOff)
    }

    ; ---- Voice selection -------------------------------------------------

    static _BuildVoiceList() {
        list := []
        try {
            tokens := this._spVoice.GetVoices()
            loop tokens.Count
                list.Push(tokens.Item(A_Index - 1))
        }
        return list
    }

    ; SAPI has no explicit quality tier, but Windows registers its higher-quality
    ; OneCore voices with "Mobile" in the description alongside the legacy Desktop
    ; ones - preferring those gives a noticeably better default voice for free.
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

        volume := settings.Has("volume") ? settings["volume"] : this._defaultVolume
        try this._spVoice.Volume := volume
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
            "volume", this._spVoice.Volume,
            "speed", this._defaultSpeed
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
        volumeSlider := panel.AddSlider("xm w232 Range" this._VOLUME_MIN "-" this._VOLUME_MAX " ToolTip", this._spVoice.Volume)
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
            this._playPauseBtn.Text := this._isPaused ? "Play" : "Pause"
    }

    static _ShowPanel() {
        panel := this._EnsurePanel()
        this._UpdatePlayPauseLabel()
        try this._volumeSlider.Value := this._spVoice.Volume
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
        if !this._IsSpeaking() && !this._isPaused
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
