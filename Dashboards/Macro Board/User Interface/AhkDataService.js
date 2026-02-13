class AhkDataService {

  static GetButtons = () => JSON.parse(ahk.sync.GetButtons());

  static TriggerButtonFunction = (button) => ahk.TriggerButtonFunction(JSON.stringify(button));
  
  static DragWindow = () => ahk.DragWindow();
}
  