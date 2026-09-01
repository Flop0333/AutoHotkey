; ============================================================================
; === Desktop & RequiredWindow Classes - Virtual Desktop Implementation ======
; ============================================================================
;
; Desktop class manages individual virtual desktops with auto-launching windows.
; RequiredWindow class defines applications that should be present on a desktop.
;
; Internal implementation - see Desktops Manager.ahk for user setup guide.
; ============================================================================

#Include ..\..\Lib\Core\SafeCall.ahk

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
    ; Run on-leave action safely so it doesn't block the switch
    if HasMethod(onLeaveAction, "Call")
        SafeCall("desktops.onleave." this._number, onLeaveAction, { serviceId: "desktops_manager" })
    DesktopsDDL.desktopsHistory.Push(this._number)
    DesktopsDDL.GotoDesktop(this._number)
    if this._number = DesktopsDDL.GetCurrentDesktopNumber()
      this._HandleRequiredWindows()
  }

  _HandleRequiredWindows() {
    sleep(50)
    
    for window in this._requiredWindows {

      if !WinExist(window.title) {
        if HasMethod(window.launchMethod, "Call")
            SafeCall("desktops.launch." this._number, window.launchMethod, { serviceId: "desktops_manager", meta: { title: window.title } })
        ; NOTE: if launchMethod is not callable we skip silently
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
  launchMethod  := BoundFunc ; () => "" ; default no-op launch method
  activate      := false ; Launch app minimized/in background or activate and maximize it

  __New(title, launchMethod, activate := true) {
    this.title := title
    this.launchMethod := launchMethod
    this.activate := activate
  }
}
