#Requires AutoHotkey v2
#SingleInstance Force
#Include ..\..\..\Core.ahk
#Include ..\..\Info.ahk
#Include My Model.ahk

USER_INTERFACE_PATH := Paths.autohotkey "\Webview Template\User Interface"
TraySetIcon(USER_INTERFACE_PATH "\assets\tray icon.png")

Class MyApp extends WebViewToo {
	static WIN_TITLE := "My App"
	static showOptions := {}

	__New() {
		super.__new()
		this.BorderSize := 1  ; Increase border size for easier resizing
		
		this.SetVirtualHostNameToFolderMapping("app.local", USER_INTERFACE_PATH, 0) ; block cors error, allow loading local files
		this.Load("http://app.local/index.html")
		this.AddCallbackToScript("GetAhkObjects", (WebView) => this.GetObjectsForWeb())
		this.AddCallbackToScript("TriggerButtonFunction", (webView, button) => this.TriggerButtonFunction(webView, button))
		; this.OpenDevToolsWindow()
		
		this.showOptions := Format("x{} y{} w{} h{}", 10, 10, 500, 500)
		this.Show()
	}

	Show() => super.Show(this.showOptions, MyApp.WIN_TITLE)
	
	GetObjectsForWeb() {
		myObjects := []
		myObjects.Push( MyModel("TestFunction", "Test Function 1", "image.png") )
		myObjects.Push( MyModel("TestFunction", "Test Function 2", "picture.jpg") )

		; Cast function references to their names in string format for JSON serialization
		for object in myObjects
			object.funcName := object.funcName.Name

		return json.Dump(myObjects) ; Example output: [{"funcName":"OpenNotionShitFixen","image":"notion.gif","tooltip":"S H I T  F I X E N"},{"funcName":"OpenFinancien","image":"tetris.gif","tooltip":"Financiën Sheet"}}]
	}

	TriggerButtonFunction(WebView, button) => %button.funcName%()
}

TestFunction() {
	MsgBox("Test function triggered from webview!")
}

