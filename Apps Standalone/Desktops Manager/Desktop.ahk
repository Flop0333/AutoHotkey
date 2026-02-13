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
        this._DisplayLaunchingMessage(window.title)
        try window.launchMethod.Call()
      } 
      else if window.activate = true {
          try WinMaximize(window.title)
          try WinActivate(window.title)
      }
    }
  }

  _DisplayLaunchingMessage(title) {
    desktopMessageGui := DarkGui("-Caption +Owner").FontSize(15)
    desktopMessageGui.BackColor := "0x1F1F1F"
    textField := desktopMessageGui.AddText("Center -E0x200 Background0x1F1F1F w200 h25", "Launching " title)
    WinSetTransparent(255, desktopMessageGui)
    WinSetRegion("0-0 w290 h60 r20-20", desktopMessageGui) ; this casus a small flash at the top of the gui. TODO: create more spare at top and move whole thing down?
    
    startTime := A_TickCount
    duration := 1300 ; ms
    SetTimer(_ShowGuiAtMousePos, 20)
    
    _ShowGuiAtMousePos() {
      CoordMode("Mouse")
      MouseGetPos(&xPos, &yPos)
      x := xPos - 130
      y := yPos + 15
      desktopMessageGui.Show(Format("x{} y{}", x, y))
      elapsedTime := A_TickCount - startTime
      
      ; Check if the duration has passed
      if (elapsedTime > duration) {
        SetTimer(_ShowGuiAtMousePos, 0) ; stop
        desktopMessageGui.Destroy()
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
