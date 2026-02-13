#Include SearchEngine.ahk
#Include SearchEnginesState.ahk
#Include ../BaseDatabaseService.ahk

Class SearchEnginesDatabaseService extends BaseDatabaseService {

  STORAGE_FILE_PATH := Paths.dashboards "\Age of Efficiency\Database\Internet Search\SearchEngines.json"

  GetSearchEngines() {
    result := this.GetItems(SearchEngine)
    SearchEnginesState.SetUniqueId(result.highestId)
    return result.items
  }

  StoreSearchEngines() => this.StoreItems(SearchEnginesState.state)
}