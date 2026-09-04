#Include App.ahk
#Include AppsState.ahk
#Include ../BaseDatabaseService.ahk

Class AppsDatabaseService extends BaseDatabaseService {

  STORAGE_FILE_PATH := Paths.dashboards "\Age of Efficiency\Database\Apps\Apps.json"

  GetApps() {
    result := this.GetItems(CustomApp)
    AppsState.SetUniqueId(result.highestId)
    return result.items
  }

  StoreApps() => this.StoreItems(AppsState.state)
}