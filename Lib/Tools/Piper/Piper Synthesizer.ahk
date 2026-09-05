; ============================================================================
; Piper Synthesizer - wraps the bundled Piper TTS engine (Lib/Tools/Piper/Engine)
; ============================================================================
;
; Piper has no live streaming API: it synthesizes a complete WAV file in one
; batch. This wrapper runs the vendored piper.exe with text piped to stdin and
; returns the path to the resulting WAV file, or "" if the engine/model are
; missing or synthesis fails - callers are expected to handle that fallback.
;
; See NOTICE.md in this folder for what's bundled and its licensing.
; ============================================================================

class PiperSynthesizer {

    static ENGINE_DIR := Paths.lib "\Tools\Piper\Engine"
    static ENGINE_PATH := PiperSynthesizer.ENGINE_DIR "\piper.exe"
    static DEFAULT_MODEL_PATH := Paths.lib "\Tools\Piper\Voices\en_US-lessac-medium\en_US-lessac-medium.onnx"

    static IsAvailable(modelPath := this.DEFAULT_MODEL_PATH) {
        return FileExist(this.ENGINE_PATH) != "" && FileExist(modelPath) != ""
    }

    ; Synthesizes text via the bundled engine and returns a path to a temporary
    ; WAV file, or "" if the engine/model aren't present or synthesis fails.
    static Synthesize(text, modelPath := this.DEFAULT_MODEL_PATH) {
        if !this.IsAvailable(modelPath) || !text
            return ""

        outputPath := A_Temp "\piper-tts-" A_TickCount "-" Random(1000, 9999) ".wav"
        try FileDelete(outputPath)

        try {
            shell := ComObject("WScript.Shell")
            shell.CurrentDirectory := this.ENGINE_DIR
            ; Invoked directly (no cmd.exe /C) - avoids cmd's well-known quoting
            ; quirk where a quoted exe path followed by more quoted args gets
            ; mis-parsed, and we don't need any shell features here anyway.
            command := Format('"{1}" --model "{2}" --output_file "{3}"', this.ENGINE_PATH, modelPath, outputPath)
            exec := shell.Exec(command)
            exec.StdIn.Write(text)
            exec.StdIn.Close()
            while exec.Status = 0
                Sleep(20)
        } catch {
            return ""
        }

        return FileExist(outputPath) ? outputPath : ""
    }
}
