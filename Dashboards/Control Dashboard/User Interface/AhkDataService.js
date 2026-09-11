// The only place that talks to the AutoHotkey host. Every section goes through
// these calls instead of touching `ahk` directly.
class AhkDataService {

  // Asked once at startup: the section a caller requested before this page
  // existed, or an empty string.
  static GetPendingSection = () => JSON.parse(ahk.sync.GetPendingSection());

  static GetSuiteStatus = () => JSON.parse(ahk.sync.GetSuiteStatus());

  static GetLogEntries = () => JSON.parse(ahk.sync.GetLogEntries());

  static SetClipboard = (text) => ahk.SetClipboard(text);

  static LogTestMessage = (severity) => JSON.parse(ahk.sync.LogTestMessage(severity));

  // Actions. Reload and exit end this process, so they are not awaited.
  static ReloadSuite = () => ahk.ReloadSuite();

  static ExitSuite = () => ahk.ExitSuite();

  static RunAllTests = () => JSON.parse(ahk.sync.RunAllTests());

  static GetTestRuns = () => JSON.parse(ahk.sync.GetTestRuns());

  static GetGitStatus = () => ahk.GetGitStatus().then(JSON.parse);

  static GetHealth = () => JSON.parse(ahk.sync.GetHealth());

  static GetProcesses = () => JSON.parse(ahk.sync.GetProcesses());

  static GetProfiles = () => JSON.parse(ahk.sync.GetProfiles());

  // Records the choice; the reload that applies it is a separate call, so a
  // profile that cannot be saved is reported before the suite restarts.
  static RequestProfile = (displayName) => JSON.parse(ahk.sync.RequestProfile(displayName));

  // Scripts are addressed by process id, so no path crosses the bridge.
  static RestartScript = (processId) => JSON.parse(ahk.sync.RestartScript(processId));

  static StartExpectedScript = (scriptName) => JSON.parse(ahk.sync.StartExpectedScript(scriptName));

  static StopScript = (processId) => JSON.parse(ahk.sync.StopScript(processId));

  // Opening a folder can fail (a missing path, a blocked shell), so these
  // report their outcome instead of being fire-and-forget.
  static OpenLogArchive = () => JSON.parse(ahk.sync.OpenLogArchive());

  static OpenLogFolder = () => JSON.parse(ahk.sync.OpenLogFolder());

  static OpenRepository = () => JSON.parse(ahk.sync.OpenRepository());
}
