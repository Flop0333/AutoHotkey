class AhkDataService {

  static GetTestRuns = () => JSON.parse(ahk.sync.GetTestRuns());

  static GetStatus = () => JSON.parse(ahk.sync.GetStatus());

  static RunTests = () => ahk.RunTests();

  static SetClipboard = (text) => ahk.SetClipboard(text);
}
