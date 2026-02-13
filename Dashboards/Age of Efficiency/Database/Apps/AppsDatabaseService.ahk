#Include App.ahk
#Include AppsState.ahk
#Include ../BaseDatabaseService.ahk

Class AppsDatabaseService extends BaseDatabaseService {

  STORAGE_FILE_PATH := Paths.dashboards "\Age of Efficiency\Database\Apps\Apps.json"

  GetApps() {
    result := this.GetItems(CustomApp)
    AppsState.SetUniqueId(result.highestId)
    _apps := {apps: [], argumentApps: [], allApps: result.items}
    for app in result.items {
      if app.argumentRequired
        _apps.argumentApps.Push(app)
      else
        _apps.apps.Push(app)
    }
    return _apps
  }

  StoreApps() => this.StoreItems(AppsState.state.allApps)
}