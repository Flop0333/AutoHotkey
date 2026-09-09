#Include SearchEngine.ahk
#Include ../BaseDatabaseService.ahk
#Include ..\..\..\..\Lib\Core\Paths.ahk

Class SearchEnginesDatabaseService extends BaseDatabaseService {

  STORAGE_FILE_PATH := Paths.dashboards "\Age of Efficiency\Database\Internet Search\SearchEngines.json"

  Load() => this.GetItems(SearchEngine)

  Store(items) => this.StoreItems(items)
}
