// The only place that talks to the AutoHotkey host. Every section goes through
// these calls instead of touching `ahk` directly.
class AhkDataService {

  static GetSuiteStatus = () => JSON.parse(ahk.sync.GetSuiteStatus());

  static GetLogEntries = () => JSON.parse(ahk.sync.GetLogEntries());

  static SetClipboard = (text) => ahk.SetClipboard(text);

  static LogTestMessage = (severity) => JSON.parse(ahk.sync.LogTestMessage(severity));

  // Actions. Reload and exit end this process, so they are not awaited.
  static ReloadSuite = () => ahk.ReloadSuite();

  static ExitSuite = () => ahk.ExitSuite();

  static RunAllTests = () => JSON.parse(ahk.sync.RunAllTests());

  static GetGitStatus = () => ahk.GetGitStatus().then(JSON.parse);

  static GetHealth = () => JSON.parse(ahk.sync.GetHealth());

  // Opening a folder can fail (a missing path, a blocked shell), so these
  // report their outcome instead of being fire-and-forget.
  static OpenLogArchive = () => JSON.parse(ahk.sync.OpenLogArchive());

  static OpenLogFolder = () => JSON.parse(ahk.sync.OpenLogFolder());

  static OpenRepository = () => JSON.parse(ahk.sync.OpenRepository());
}
