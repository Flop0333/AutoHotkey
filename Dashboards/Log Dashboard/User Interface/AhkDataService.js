class AhkDataService {

  static GetLogEntries = () => JSON.parse(ahk.sync.GetLogEntries());

  static SetClipboard = (text) => ahk.SetClipboard(text);

  static LogTestMessage = (severity) => ahk.LogTestMessage(severity);

  static GetGitStatus = () => ahk.GetGitStatus().then(JSON.parse);
}
