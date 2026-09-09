#Include App.ahk
#Include ../BaseDatabaseService.ahk
#Include ..\..\..\..\Lib\Core\Paths.ahk

Class AppsDatabaseService extends BaseDatabaseService {

  STORAGE_FILE_PATH := Paths.dashboards "\Age of Efficiency\Database\Apps\Apps.json"

  Load() => this.GetItems(CustomApp)

  Store(items) => this.StoreItems(items)
}
