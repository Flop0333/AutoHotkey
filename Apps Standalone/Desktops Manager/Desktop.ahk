; ============================================================================
; === Desktop & RequiredWindow Classes - Virtual Desktop Implementation ======
; ============================================================================
;
; Desktop class manages individual virtual desktops with auto-launching windows.
; RequiredWindow class defines applications that should be present on a desktop.
;
; Internal implementation - see Desktops Manager.ahk for user setup guide.
; ============================================================================

Class Desktop {

  onLeaveAction     := ""

  __New(number, requiredWindows*) {
    this._number := number
    this._requiredWindows := requiredWindows
  }
  
  OnLeave(action) {
    this.onLeaveAction := action
    return this
  }
  
  SwitchTo(onLeaveAction) {
    try onLeaveAction.Call()
    DesktopsDDL.desktopsHistory.Push(this._number)
    DesktopsDDL.GotoDesktop(this._number)
    if this._number = DesktopsDDL.GetCurrentDesktopNumber()
      this._HandleRequiredWindows()
  }

  _HandleRequiredWindows() {
    sleep(50)
    
    for window in this._requiredWindows {

      if !WinExist(window.title) {
        try window.launchMethod.Call() ; TODO: this does open a browser tab in a brower that is allready open (on another desktop) instead of opening it one the desktops switched too
      } 
      else if window.activate = true {
          try WinMaximize(window.title)
          try WinActivate(window.title)
      }
    }
  }
} 

Class RequiredWindow {

  title         := String
  launchMethod  := BoundFunc ; () => MsgBox()
  activate      := false ; Launch app minimized/in background or activate and maximize it

  __New(title, launchMethod, activate := true) {
    this.title := title
    this.launchMethod := launchMethod
    this.activate := activate
  }
}
