; ============================================================================
; === Command Input Handler ==================================================
; ============================================================================
;
; [FEATURES]
;   - Provides a GUI for command input with real-time suggestions
;   - Integrates with Bookmarks, Apps, and Search Engines states
;   - Executes commands via CommandExecutor
;	- Hotkeys for submission (Enter), cancellation (Escape), and navigation (Down)
; ============================================================================

#Include ../Database/Apps/AppsState.ahk
#Include ../Database/Bookmarks/BookmarksState.ahk
#Include ../Database/Internet Search/SearchEnginesState.ahk
#Include Command Executor.ahk
#Include ..\..\..\Lib\Core\Paths.ahk

Class CommandInput extends DarkGui {

	static TOP_MARGIN := Round(A_ScreenHeight / 3.5)
	static _WIN_TITLE 	:= "Input Launcher"
	_WIDTH     	:= 1200
	
	_commandsPreview := CommandsPreview
	_isWaiting := false
	_input := ""
	_previousInput := ""
	_height := 150
	
	__New() {
		this._commandsPreview := CommandsPreview()
		this._CreateGui()
		this._ActivateHotkeys()
 	}

	_CreateGui() {
		super.__New("+AlwaysOnTop -Caption", CommandInput._WIN_TITLE).FontSize(30)
		this.AddPicture("x0 y0 h160 w" this._WIDTH, Paths.dashboards "\Age of Efficiency\Library\chatbar.png")
		this.BackColor := "0x000000"
		WinSetTransColor("0x000000", this)
		this.inputField := this.AddEdit("x150 y50 h55 w" this._WIDTH - 300 " Center -E0x200 Background0x1F1F1F")
	}
	
	WaitForInputAndExecute() => CommandExecutor.Execute(this.WaitForInput())
	
	WaitForArgumentAndExecute(command) => CommandExecutor.Execute(command " " this.WaitForInput())

	WaitForInput() {
		this._Show()
		this._commandsPreview := ""
		this._commandsPreview := CommandsPreview() ; Setting a new instance of CommandsPreview fixed bug to not show preview after closing
		this._ActivatePreviewUpdater()
		this._isWaiting := true
		while this._isWaiting {
			; Close automatically when focus is lost
			if !WinActive(CommandInput._WIN_TITLE) && this._isWaiting {
				this._Finish()
				break
			}
		}
		return this._input
	}

	_Show() => super.Show(Format("h{} w{} y{}",this._height, this._WIDTH, CommandInput.TOP_MARGIN))

	_ActivatePreviewUpdater() {
		SetTimer(_CheckForChanges, 10)
		
		_CheckForChanges() {
			if this._isWaiting = false
				SetTimer(_CheckForChanges, 0) ; Stop timer
			
			; Update preview if input has changed
			currentInput := this.inputField.Text
			if currentInput = this._previousInput
				return
			
			this._commandsPreview.UpdatePreview(currentInput)
			this._previousInput := currentInput
		}
	}
	
	_InsertNextCommandFromPreview() {
		try firstSuggestionLine := StrSplit(this._commandsPreview.suggestionsText, "`r`n")[1]
		catch
			return
		firstSuggestionLinesCommand := StrSplit(firstSuggestionLine, A_Space)[1]
		this.inputField.Text := firstSuggestionLinesCommand
		Send("^{Right}") ; Set cursor to end of input
	}

	_ActivateHotkeys() {
		HotIfWinActive(CommandInput._WIN_TITLE)
			Hotkey("Enter", (*) => this._Finish())
			Hotkey("Escape", (*) => WinClose(CommandInput._WIN_TITLE))
			Hotkey("^Backspace", (*) =>  Send("^+{Left}{Backspace}"))
			Hotkey("Down", (*) =>  this._InsertNextCommandFromPreview())
	}

	_Finish() {
		this._input := this.inputField.Text
		this._isWaiting := false
		this.inputField.Text := ""
		try this.Hide()
	}
}


Class CommandsPreview extends DarkGui {
	
	suggestionsText			:= String ; Used in CommandInput to get the first suggestion command
	
	_HEADER_SPACER_HEIGHT	:= 20
	_ITEM_HEIGHT			:= 40
	_WIDTH					:= 590
	_MIN_HEIGHT 			:= 60
	_BOTTOM_PADDING 		:= 30
	_ITEM_SPACE_MULTIPLIER	:= 37
	_TOP_MARGIN 			:= CommandInput.TOP_MARGIN + 150 ; Height of input box
	_MAX_HEIGHT				:= A_ScreenHeight - this._TOP_MARGIN - 190 ; taskbar height
	_TRANSPARENCY_AMOUNT	:= 250 ; 0/255
	
	hasCurrentAction		:= false

	__New() {		
		_ := super.__New("-Caption +Owner").FontSize(23)
		this.BackColor := "0x1F1F1F"
		this.headerSpacer := this.AddEdit("-VScroll -E0x200 x0 y0 h" this._HEADER_SPACER_HEIGHT " w" this._WIDTH)
		this.actionTextField := this.AddEdit("-VScroll -E0x200 Background0x2a362c x0 y" this._HEADER_SPACER_HEIGHT " h" this._ITEM_HEIGHT " w" this._WIDTH)
		this.actionTextField.Opt("Center")
		this.suggestionsTextField := this.AddEdit("-VScroll -E0x200 Background0x1F1F1F x0 y" this._HEADER_SPACER_HEIGHT + this._ITEM_HEIGHT " h" this._MAX_HEIGHT " w" this._WIDTH)
		this.suggestionsTextField.Opt("+VScroll") ; Make it scrollable after disableing will remove the scrollbar itself. wtf
		this.suggestionsTextField.Opt("Center")
		WinSetTransparent(this._TRANSPARENCY_AMOUNT, this)
	}

	UpdatePreview(currentInput := String) {
		if currentInput = "" {
			this.Show("h0") ; bugfix: set the height to 0 to make sure when displaying it the next time, the previous height will not be shown for a milisecond
			this.Hide()
			return
		}
		
		currentAction := this._GetCurrentActionFromAllStates(currentInput)
		suggestions := this._GetSuggestionsFromAllStates(currentInput)

		if currentAction = "" && !suggestions.Has(1) {
			this.Show("h0")
			this.Hide()
			return
		}
		
		this._SetPreviewText(currentAction, suggestions)
		amountOfLines := StrSplit(this.suggestionsTextField.Text, "`n").Length
		this._Show(amountOfLines)
	}
	
	_Show(amountOfLines := Number){
		if this.hasCurrentAction
			amountOfLines += 1 ; Add a line for the action textfield
		height := amountOfLines = 1 ? this._MIN_HEIGHT : (amountOfLines * this._ITEM_SPACE_MULTIPLIER) + this._BOTTOM_PADDING
		if height > this._MAX_HEIGHT
			height := this._MAX_HEIGHT
		super.Show(Format('xCenter NoActivate w{} h{} y{}', this._WIDTH, height, this._TOP_MARGIN))
	}

	_GetCurrentActionFromAllStates(currentInput := String) {
		; When typing the argument, still show the command by extracting the command from the currentInput
		try { 
			StrSplit(currentInput, A_Space)[2] ;  if the argument is found
			currentInput := StrSplit(currentInput, A_Space)[1] ; Reset the currentInput to only the command of the input
			isTypingArgument := true
		}
		catch
			isTypingArgument := false

		currentAction := AppsState.GetByCommandOrTitle(currentInput)
		if currentAction != "" {
			isTypingArgumentForCommandWithArgument := isTypingArgument = true && currentAction.argumentRequired = true ; When typing the argument, don't show an actions without an argument
			if isTypingArgument = false || isTypingArgumentForCommandWithArgument
				return currentAction
		}
		
		currentAction := BookmarksState.GetByCommandOrTitle(currentInput)
		if currentAction != "" && isTypingArgument = false ; Bookmarks don't accept arguments
			return currentAction

		return SearchEnginesState.GetByCommandOrTitle(currentInput) ; Don't check for isTypingArgument, because all SeachEngines accept argument
	}

	_GetSuggestionsFromAllStates(currentInput := String) {
		suggestions := AppsState.GetSuggestionsByCommand(currentInput)

		for bookmarkSuggestion in BookmarksState.GetSuggestionsByCommand(currentInput) 
			suggestions.Push(bookmarkSuggestion)

		for searchEngineSuggestion in SearchEnginesState.GetSuggestionsByCommand(currentInput) 
			suggestions.Push(searchEngineSuggestion)

		return suggestions
	}

	_SetPreviewText(currentAction := CustomApp, suggestions := Array) {
		try currentAction := currentAction.title

		if currentAction != "" && suggestions.Has(1)
			currentAction .= "`r`n" ; Add a linebreak when an action if followed by suggestions
		
		suggestionsText := ""
		for index, indexCommand in suggestions {
			suggestionsText .= indexCommand.command " => " indexCommand.title
				if index < suggestions.Length
					suggestionsText .= "`r`n"
			}

		this.actionTextField.Text := currentAction
		this.hasCurrentAction := currentAction != ""
		if this.hasCurrentAction {
			this.headerSpacer.Opt("Background0x2a362c")
			this.actionTextField.Move(,this._HEADER_SPACER_HEIGHT,this._WIDTH,this._ITEM_HEIGHT) ; Restore action textfield visible
			this.suggestionsTextField.Move(,this._ITEM_HEIGHT + this._HEADER_SPACER_HEIGHT)
		}
		else {
			this.headerSpacer.Opt("Background0x1F1F1F")
			this.actionTextField.Move(0,0,0,0) ; Hide action textfield by moving it out of view
			this.suggestionsTextField.Move(,this._HEADER_SPACER_HEIGHT)
		}

		; Force immediate repaint of controls — prevents needing to hover to see changes
		try DllCall("RedrawWindow", "Ptr", this.headerSpacer.Hwnd, "Ptr", 0, "Ptr", 0, "UInt", 0x185)

		this.suggestionsTextField.Text := suggestionsText
		this.suggestionsText := suggestionsText
	}
}
