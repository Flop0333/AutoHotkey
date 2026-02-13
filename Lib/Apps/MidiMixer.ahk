#Include App.ahk
#Include ..\Core\Paths.ahk

class MidiMixer extends App {
	static __New() => App.Init(
		winTitle := "MIDI Mixer",
		ahk_exe := "MIDI Mixer.exe",
		path := Paths.windows.LocalAppData "\Programs\midi-mixer-app"
	)

	static Open() {
		if this.IsRunning() {
			this.Activate()
			return
		}
		SetKeyDelay(20)
		Run(this.path) ; Open folder
		Sleep 500
		Send("midi {Enter}") ; Select & click on Midi Mixer
		WinWait("MIDI Mixer")
		WinClose("midi-mixer-app") ; Close File Explorer
		WinMaximize("ahk_exe " this.ahk_exe)
	}
}
