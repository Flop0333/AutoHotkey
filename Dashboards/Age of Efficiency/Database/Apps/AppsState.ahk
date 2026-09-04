#Include AppsDatabaseService.ahk
#Include ../BaseState.ahk

Class AppsState extends BaseState {

  static __New() => this.state := AppsDatabaseService().GetApps()

  static Store() => AppsDatabaseService().StoreApps()
}
