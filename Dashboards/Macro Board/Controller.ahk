#Requires AutoHotkey v2
#SingleInstance Force
#Include ..\..\Lib\Core.ahk
#Include ..\..\Lib\Core\WebView.ahk
#Include Settings\Settings Service.ahk
#Include Settings\Window State Tracker.ahk

USER_INTERFACE_PATH := Paths.dashboards "\Macro Board\User Interface"
TraySetIcon(USER_INTERFACE_PATH "\assets\tray icon.png")

Class MacroBoard extends WebViewToo {
	static WIN_TITLE := "Macro Board"
	static showOptions := {}
	settingsService := SettingsService

	__New(buttons, settingsPath :=  Paths.dashboards "\Macro Board\Settings\Profile Settings\" ProfileManager.current.displayName " settings.ini") {
		super.__new()
		this.settingsService := SettingsService(settingsPath)
		this.BorderSize := 1  ; Increase border size for easier resizing
		
		this.SetVirtualHostNameToFolderMapping("app.local", USER_INTERFACE_PATH, 0) ; block cors error, allow loading local files
		this.Load("http://app.local/index.html")
		this.AddCallbackToScript("GetButtons", 				(*) => this.GetButtonsForWeb(buttons))
		this.AddCallbackToScript("TriggerButtonFunction", 	(webView, button) => TriggerButtonFunction(button))
		
		this.showOptions := Format("x{} y{} w{} h{}", this.settingsService.Window.x, this.settingsService.Window.y, this.settingsService.Window.Width, this.settingsService.Window.Height)
		this.Show()
		; this.OpenDevToolsWindow()
		
		; Initialize window state tracker
		WindowPositionTracker(this.Gui, this.settingsService)
	}

	Show() => super.Show(this.showOptions, MacroBoard.WIN_TITLE)
	
	; Keep the GUI at the bottom persistently by re-applying Z-order periodically.
	PlaceOnBottom() {
		interval := 2000 ; ms
		SetTimer(() => DllCall("SetWindowPos", "Ptr", this.Hwnd, "Ptr", 1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x13), interval)
		return this
	}

	GetButtonsForWeb(buttons) {
		; Create a copy for serialization without modifying the original
		serializedButtons := []
		
		for button in buttons {
			serializedBtn := {
				funcName: button.funcName.Name,
				tooltip: button.tooltip,
				isToggle: button.isToggle,
				image: button.image
			}
			
			; For toggle buttons, add state function name and current state
			if button.isToggle {
				serializedBtn.getStateFunc := button.getStateFunc.Name
				serializedBtn.state := button.getStateFunc.Call()
			}
			
			serializedButtons.Push(serializedBtn)
		}

		return Json.Dump(serializedButtons)
	}
}

ConvertToObject(jsonString, objectType := {}) {
	objectMap := Json.parse(jsonString)
	returnObject := Button
	for key, value in objectMap 
		returnObject.%key% := value

	return returnObject
}

TriggerButtonFunction(jsonButton) {
	button := JSON.ToObject(jsonButton)

	; Execute the button's function
	%button.funcName%()
	
	; If it's a toggle button, return the new state
	if button.isToggle
		return %button.getStateFunc%()
}