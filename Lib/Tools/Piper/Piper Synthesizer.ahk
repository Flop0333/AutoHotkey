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
        inputPath := A_Temp "\piper-input-" A_TickCount "-" Random(1000, 9999) ".txt"
        try FileDelete(outputPath)

        try {
            FileAppend(text, inputPath, "UTF-8-RAW")
            inner := Format('"{1}" --model "{2}" --output_file "{3}"', this.ENGINE_PATH, modelPath, outputPath)
            ; piper.exe only takes text on stdin, which needs cmd.exe's "<" to
            ; redirect from a file - but cmd mis-parses this command's several
            ; quoted segments unless the whole thing is wrapped in one more
            ; pair of quotes (the same quirk worked around in a different way
            ; elsewhere; WScript.Shell.Exec avoided it before, but always
            ; shows a visible console window, which cmd.exe run with AHK's
            ; Run/RunWait "Hide" does not).
            commandLine := A_ComSpec ' /C "' inner ' < "' inputPath '""'
            RunWait(commandLine, this.ENGINE_DIR, "Hide")
        } catch {
            return ""
        } finally {
            try FileDelete(inputPath)
        }

        return FileExist(outputPath) ? outputPath : ""
    }
}
