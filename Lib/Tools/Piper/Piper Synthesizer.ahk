; ============================================================================
; Piper Synthesizer - wraps the bundled Piper TTS engine (Lib/Tools/Piper/Engine)
; ============================================================================
;
; Spawning a fresh piper.exe per utterance reloads its ~60MB voice model from
; disk every time (roughly 1-3 seconds), which made Speak() feel unusably
; slow. Instead, one piper.exe process is kept running in the background
; (started via WarmUp(), ideally called once at app startup so the model is
; already loaded before the user's first request) and reused for every call:
; text goes in on its stdin, one line per request; the resulting WAV path
; comes back on its stdout, one line per response, in the same order.
;
; See NOTICE.md in this folder for what's bundled and its licensing.
; ============================================================================

class PiperSynthesizer {

    static ENGINE_DIR := Paths.lib "\Tools\Piper\Engine"
    static ENGINE_PATH := PiperSynthesizer.ENGINE_DIR "\piper.exe"
    static DEFAULT_MODEL_PATH := Paths.lib "\Tools\Piper\Voices\en_US-lessac-medium\en_US-lessac-medium.onnx"
    static OUTPUT_DIR := A_Temp "\piper-tts-output"

    static _exec := ""     ; WshScriptExec of the persistent engine process
    static _modelPath := "" ; which model that process was started with

    static IsAvailable(modelPath := this.DEFAULT_MODEL_PATH) {
        return FileExist(this.ENGINE_PATH) != "" && FileExist(modelPath) != ""
    }

    ; Starts the persistent engine process in the background so its voice
    ; model is already loaded by the time Synthesize() is first called. Cheap
    ; and safe to call any time - it only actually (re)spawns when needed.
    static WarmUp(modelPath := this.DEFAULT_MODEL_PATH) {
        if this.IsAvailable(modelPath)
            this._EnsureProcess(modelPath)
    }

    ; Synthesizes text via the persistent engine process and returns a path to
    ; the resulting WAV file, or "" if the engine/model aren't present or
    ; synthesis fails.
    static Synthesize(text, modelPath := this.DEFAULT_MODEL_PATH) {
        if !this.IsAvailable(modelPath) || !text
            return ""

        exec := this._EnsureProcess(modelPath)
        if exec = ""
            return ""

        try {
            ; piper treats each stdin line as one synthesis request and
            ; replies with exactly one stdout line (the output path) per
            ; request, in order - a multi-line selection must collapse to one
            ; line, or it would be split into several requests and desync
            ; every read after it.
            exec.StdIn.WriteLine(this._SanitizeForSingleLine(text))
            outputPath := Trim(exec.StdOut.ReadLine(), "`r`n")
        } catch {
            ; The persistent process likely died - drop it so the next call respawns it.
            this._exec := ""
            return ""
        }

        return FileExist(outputPath) ? outputPath : ""
    }

    static _EnsureProcess(modelPath) {
        if this._exec != "" && this._modelPath = modelPath && this._exec.Status = 0
            return this._exec

        try this._exec.Terminate()
        this._exec := ""

        try DirCreate(this.OUTPUT_DIR)

        try {
            shell := ComObject("WScript.Shell")
            shell.CurrentDirectory := this.ENGINE_DIR
            command := Format('"{1}" --model "{2}" --output_dir "{3}" --quiet', this.ENGINE_PATH, modelPath, this.OUTPUT_DIR)
            exec := shell.Exec(command)
            this._TryHideConsole(exec.ProcessID)
            this._exec := exec
            this._modelPath := modelPath
        } catch {
            return ""
        }

        return this._exec
    }

    ; Best-effort only: WScript.Shell.Exec always shows a console window for
    ; console apps, with no way to request a hidden one. This process now only
    ; spawns once (at warm-up), not per utterance, so a brief flash here is
    ; far less disruptive than before - but try to hide it anyway.
    static _TryHideConsole(pid) {
        loop 25 {
            if DllCall("kernel32.dll\AttachConsole", "UInt", pid, "Int") {
                hwnd := DllCall("kernel32.dll\GetConsoleWindow", "Ptr")
                if hwnd
                    try DllCall("ShowWindow", "Ptr", hwnd, "Int", 0) ; SW_HIDE
                DllCall("kernel32.dll\FreeConsole")
                return
            }
            Sleep(20)
        }
    }

    static _SanitizeForSingleLine(text) => StrReplace(StrReplace(text, "`r`n", " "), "`n", " ")
}
