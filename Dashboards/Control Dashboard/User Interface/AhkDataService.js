// The only place that talks to the AutoHotkey host. Every section goes through
// these calls instead of touching `ahk` directly.
class AhkDataService {

  static GetSuiteStatus = () => JSON.parse(ahk.sync.GetSuiteStatus());

  static GetLogEntries = () => JSON.parse(ahk.sync.GetLogEntries());

  static SetClipboard = (text) => ahk.SetClipboard(text);

  static LogTestMessage = (severity) => ahk.LogTestMessage(severity);

  static GetGitStatus = () => ahk.GetGitStatus().then(JSON.parse);

  static OpenLogArchive = () => ahk.OpenLogArchive();
}
