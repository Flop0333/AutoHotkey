Class DarkGui extends Gui {

	static BACKGROUND_COLOR := "171717"
	static WHITE_COLOR := "C5C5C5"
	static FONT_SIZE := 20

	__New(Options := "-Caption", Title := A_ScriptName, EventObj?) {
		super.__new(Options, Title, EventObj?)
		this.DarkMode().MakeFontNicer()
		return this
	}
	
	DarkMode(fontSize := DarkGui.FONT_SIZE) {
		this.BackColor := DarkGui.BACKGROUND_COLOR
		this.MakeFontNicer(fontSize).FontSize(fontSize)
		return this
	}
		
	FontSize(fontSize := DarkGui.FONT_SIZE) => (this.SetFont("s" fontSize), this)

	MakeFontNicer(fontSize := DarkGui.FONT_SIZE) => (this.SetFont("c" DarkGui.WHITE_COLOR, "Consolas"), this)

	PressTitleBar() => (PostMessage(0xA1, 2,,, this), this)

	NeverFocusWindow() => (WinSetExStyle("0x08000000L", this), this)

	MakeClickthrough() {
		WinSetTransparent(255, this)
		this.Opt("+E0x20")
		return this
	}
}
