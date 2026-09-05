class AhkDataService {

  static GetLogEntries = () => JSON.parse(ahk.sync.GetLogEntries());
}
