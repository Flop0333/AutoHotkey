; ============================================================================
; === Info Tool ==============================================================
; ============================================================================
;
; [EXAMPLE]
;   Info("test 1").KeepShowing().SingleInfoMode()
;  	Info("test 2")
; 	Info("test 1").ReplaceText("new text for test 1")
;  	Info.DestroyAll()

#Include ..\Extensions\Dark Gui.ahk
#Include ..\Extensions\String.ahk

class Info {

	/**
	 * To use Info, you just need to create an instance of it, no need to call any method after
	 * @param text *String*
	 * @param autoCloseTimeout *Integer* in milliseconds. Doesn't close automatically when set to 0
	 */
	__New(text, autoCloseTimeout := 2000) {
		this.autoCloseTimeout := autoCloseTimeout
		this.text := text
		this._CreateGui()
		this.hwnd := this.gInfo.hwnd
		if Info.singleInfoMode {
			Info.DestroyAll()
		}
		if !this._GetAvailableSpace() {
			this._StopDueToNoSpace()
			return
		}
		this._SetupHotkeysAndEvents()
		this._SetupAutoclose()
		this._Show()
	}

	KeepShowing() {
		SetTimer(this.bfDestroy, 0)  ; Cancel any existing timer
		this.autoCloseTimeout := 0
		return this
	}

	; Only one Info window is shown at a time
	SingleInfoMode() {
		Info.singleInfoMode := true
		return this
	}


	static fontSize     := 20
	static distance     := 3
	static unit         := A_ScreenDPI / 96
	static guiWidth     := Info.fontSize * Info.unit * Info.distance
	static maximumInfos := Floor(A_ScreenHeight / Info.guiWidth)
	static spots        := Info._GeneratePlacesArray()
	static foDestroyAll := (*) => Info.DestroyAll()
	static maxNumberedHotkeys := 12
	static maxWidthInChars := 104
	static singleInfoMode := false


	static DestroyAll() {
		for index, infoObj in Info.spots {
			if !infoObj
				continue
			infoObj.Destroy()
		}
	}


	static _GeneratePlacesArray() {
		availablePlaces := []
		loop Info.maximumInfos {
			availablePlaces.Push(false)
		}
		return availablePlaces
	}


	autoCloseTimeout := 0
	bfDestroy := this.Destroy.Bind(this)


	/**
	 * Will replace the text in the Info
	 * If the window is destoyed, just creates a new Info. Otherwise:
	 * If the text is the same length, will just replace the text without recreating the gui.
	 * If the text is of different length, will recreate the gui in the same place
	 * (once again, only if the window is not destroyed)
	 * @param newText *String*
	 * @returns {Infos} the class object
	 */
	ReplaceText(newText) {

		try WinExist(this.gInfo)
		catch
			return Info(newText, this.autoCloseTimeout)

		if StrLen(newText) = StrLen(this.gcText.Text) {
			this.gcText.Text := newText
			this._SetupAutoclose()
			return this
		}

		Info.spots[this.spaceIndex] := false
		return Info(newText, this.autoCloseTimeout)
	}

	Destroy(*) {
		try HotIfWinExist("ahk_id " this.gInfo.Hwnd)
		catch Any {
			return false
		}
		Hotkey("^Escape", "Off")
		Hotkey("!Escape", "Off")
		if this.spaceIndex <= Info.maxNumberedHotkeys
			Hotkey("F" this.spaceIndex, "Off")
		this.gInfo.Destroy()
		Info.spots[this.spaceIndex] := false
		return true
	}


	_CreateGui() {
		this.gInfo  := DarkGui("AlwaysOnTop -Caption +ToolWindow").FontSize(Info.fontSize).NeverFocusWindow()
		this.gcText := this.gInfo.AddText(, this._FormatText())
	}

	_FormatText() {
		String2() ; Initialize String2 methods, to make sure String object is extended
		text := String(this.text)
		lines := text.Split("`n")
		if lines.Length > 1 {
			text := this._FormatByLine(lines)
		}
		else {
			text := this._LimitWidth(text)
		}
		return text.Replace("&", "&&")
	}

	_FormatByLine(lines) {
		newLines := []
		for index, line in lines {
			newLines.Push(this._LimitWidth(line))
		}
		text := ""
		for index, line in newLines {
			if index = newLines.Length {
				text .= line
				break
			}
			text .= line "`n"
		}
		return text
	}

	_LimitWidth(text) {
		if StrLen(text) < Info.maxWidthInChars {
			return text
		}
		insertions := 0
		while (insertions + 1) * Info.maxWidthInChars + insertions < StrLen(text) {
			insertions++
			text := text.Insert("`n", insertions * Info.maxWidthInChars + insertions)
		}
		return text
	}

	_GetAvailableSpace() {
		spaceIndex := unset
		for index, isOccupied in Info.spots {
			if isOccupied
				continue
			spaceIndex := index
			Info.spots[spaceIndex] := this
			break
		}
		if !IsSet(spaceIndex)
			return false
		this.spaceIndex := spaceIndex
		return true
	}

	_CalculateYCoord() => Round(this.spaceIndex * Info.guiWidth - Info.guiWidth)

	_StopDueToNoSpace() => this.gInfo.Destroy()

	_SetupHotkeysAndEvents() {
		HotIfWinExist("ahk_id " this.gInfo.Hwnd)
		Hotkey("^Escape", this.bfDestroy, "On")
		Hotkey("!Escape", Info.foDestroyAll, "On")
		if this.spaceIndex <= Info.maxNumberedHotkeys
			Hotkey("F" this.spaceIndex, this.bfDestroy, "On")
		this.gcText.OnEvent("DoubleClick", this.bfDestroy)
		this.gInfo.OnEvent("Close", this._CopyValue)
	}

	_CopyValue(*) {
			Info("Copied!")
	}
	

	_SetupAutoclose() {
		if this.autoCloseTimeout {
			SetTimer(this.bfDestroy, -this.autoCloseTimeout)
		}
	}

	_Show(x := 0, y := this._CalculateYCoord()) => this.gInfo.Show("AutoSize NA x" x " y" y)

}
