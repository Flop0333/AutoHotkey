#Include SearchEnginesDatabaseService.ahk
#Include ../BaseState.ahk

Class SearchEnginesState extends BaseState {

  static __New() => this.state := SearchEnginesDatabaseService().GetSearchEngines()

  static Store() => SearchEnginesDatabaseService().StoreSearchEngines()
}