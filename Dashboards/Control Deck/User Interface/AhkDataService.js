// The only place that talks to the AutoHotkey host. Every section goes through
// these calls instead of touching `ahk` directly.
class AhkDataService {

  // Asked once at startup: the section a caller requested before this page
  // existed, or an empty string.
  static GetPendingSection = () => JSON.parse(ahk.sync.GetPendingSection());

  static GetSuiteStatus = () => JSON.parse(ahk.sync.GetSuiteStatus());

  static GetLogEntries = () => JSON.parse(ahk.sync.GetLogEntries());

  static MarkLogsRead = () => ahk.sync.MarkLogsRead();

  static SetClipboard = (text) => ahk.SetClipboard(text);

  static LogTestMessage = (severity) => JSON.parse(ahk.sync.LogTestMessage(severity));

  // Actions. Reload and exit end this process, so they are not awaited.
  static ReloadSuite = () => ahk.ReloadSuite();

  static ExitSuite = () => ahk.ExitSuite();

  static RunAllTests = () => JSON.parse(ahk.sync.RunAllTests());

  static GetTestRuns = () => JSON.parse(ahk.sync.GetTestRuns());

  // Git starts a process per call, so every git call is asynchronous.
  static GetGitStatus = () => ahk.GetGitStatus().then(JSON.parse);

  static GetGitBranches = () => ahk.GetGitBranches().then(JSON.parse);

  static FetchGit = () => ahk.FetchGit().then(JSON.parse);

  // The host only switches to a branch git itself lists. mode is '' for a clean
  // tree, or 'stash' or 'discard'.
  static SwitchGitBranch = (branch, mode, stashMessage) => ahk.SwitchGitBranch(branch, mode, stashMessage).then(JSON.parse);

  // Pulls what is behind, then pushes what is ahead.
  static SyncGit = () => ahk.SyncGit().then(JSON.parse);

  static GetHealth = () => JSON.parse(ahk.sync.GetHealth());

  // Counts only, like the Health section's copy: no secret names or values.
  static GetSecretsState = () => JSON.parse(ahk.sync.GetSecretsState());

  static GetProcesses = () => ahk.GetProcesses().then(JSON.parse);

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

  // Waits for VS Code's launcher to answer, so it is asynchronous.
  static OpenRepositoryInVsCode = () => ahk.OpenRepositoryInVsCode().then(JSON.parse);

  // Opens the local secrets file, whose path the host decides.
  static OpenSecretsInVsCode = () => ahk.OpenSecretsInVsCode().then(JSON.parse);
}
