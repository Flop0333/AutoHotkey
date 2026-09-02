; ============================================================================
; === User Input GUI =========================================================
; ============================================================================
;
; [EXAMPLE]
;	result := UserInput().WaitForInput()
; ============================================================================

#Include ..\Extensions\Dark Gui.ahk

class UserInput extends DarkGui {
	FONT_SIZE := 30
	COLOR := "0x1F1F1F"
	Width     := Round(A_ScreenWidth  / 1920 * 1200)
	TopMargin := Round(A_ScreenHeight / 1080 * 550)
	
	/**
	 * Get a gui to type into.
	 * Close it by pressing Escape. (This exits the entire thread)
	 * Accept your input by pressing Enter.
	 * Call WaitForInput() after creating the class instance.
	*/

	__New() {
		super.__New("-Caption").FontSize(this.FONT_SIZE)	
		WinSetTransColor(DarkGui.BACKGROUND_COLOR, this)
		
		this.InputField := this.AddEdit(
			"x50 y45 Center -E0x200 Background" this.COLOR 
			" w" this.Width - 100 " h60"
		)

		this.Input := ""
		this.isWaiting := true
		this._RegisterHotkeys()
		super.Show("y" this.TopMargin " w" this.Width)
	}

	/**
	 * Occupy the thread until you type in your input and press
	 * Enter, returns this input
	 * @returns {String}
	 */ 
	WaitForInput() {
		while this.isWaiting {
		}
		return this.Input
	}

	_SetInput() {
		this.Input := this.InputField.Text
		this.isWaiting := false
		this._Finish()
	}

	_SetCancel() {
		this.isWaiting := false
		this._Finish()
	}

	_RegisterHotkeys() {
		Hotkey("Enter", (*) => this._SetInput(), "On")
		this.OnEvent("Escape", (*) => this._SetCancel())
	}

	_Finish() {
		Hotkey("Enter", "Off")
		try this.Minimize()
		this.Destroy()
	}
}
