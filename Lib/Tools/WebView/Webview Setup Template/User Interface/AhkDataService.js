class AhkDataService {

  static GetAhkObjects = () => JSON.parse(ahk.sync.GetAhkObjects());

  static TriggerButtonFunction = (button) => ahk.TriggerButtonFunction(button);
  static DragWindow = () => ahk.DragWindow();
}
  