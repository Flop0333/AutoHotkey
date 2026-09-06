class AhkDataService {
  static GetState = () => JSON.parse(ahk.sync.GetState());

  static TogglePlay = () => ahk.TogglePlay();
  static Restart = () => ahk.Restart();
  static SetVolume = (volume) => ahk.SetVolume(volume);
  static SetSpeedIndex = (index) => ahk.SetSpeedIndex(index);

  static StopSpeaking = () => ahk.StopSpeaking();
  static DragWindow = () => ahk.DragWindow();
}
