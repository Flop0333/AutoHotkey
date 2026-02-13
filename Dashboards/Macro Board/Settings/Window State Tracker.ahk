; ============================================================================
; === Window Position Tracker ===============================================
; ============================================================================
;
; [FEATURES]
;   - Tracks the position and size of a GUI window, to be restored on next launch
;   - Saves the window state to a settings service on move/resize
;  	- Debounces timer to avoid excessive writes
;   - Validates window position to prevent saving invalid states
; ============================================================================

class WindowPositionTracker {
	DEBOUNCE_INTERVAL := 1000  ; ms
	gui := Gui
	settingsService := SettingsService
	saveTimer := ObjBindMethod(this, "SaveSettings") ; When time is up, call SaveSettings
	__New(gui, settingsService) {
		this.gui := gui
		this.settingsService := settingsService
		
		; Set up event listeners
		OnMessage(0x0003, this.StartTimer.Bind(this)) ; WM_MOVE message
		OnMessage(0x0005, this.StartTimer.Bind(this)) ; WM_SIZE message
	}

	StartTimer(wParam, lParam, msg, hwnd) {
		; Don't start timer for other gui's (if multiple are used within the same script)
		if (this.gui.Hwnd != hwnd)
			return

		SetTimer(this.saveTimer, -this.DEBOUNCE_INTERVAL) ; Negative = run once after delay
	}
	
	SaveSettings() {
		; Validate that the window is on the main monitor, not minimized and has valid dimensions
		this.gui.GetPos(&x, &y, &width, &height)
		if x < 0 || y < 0 || width < 0 || height < 0 ||  (x + width > A_ScreenWidth) || (y + height > A_ScreenHeight)
			return
		
		; Save to settings service
		this.settingsService.Window.Width := width
		this.settingsService.Window.Height := height
		this.settingsService.Window.x := x
		this.settingsService.Window.y := y
		this.settingsService.SaveFile()
	}
}