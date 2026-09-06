#Include ..\..\Lib\Core.ahk
#Include ..\..\Lib\Core\WebView.ahk

Class LoggerPopup extends WebViewToo {
	static WIDTH := 300
	static HEIGHT := 140
	static SHOW_DELAY := 5000 ; ms after the last log entry before the popup appears

	counts := Map("info", 0, "warning", 0, "error", 0)
	latestEntry := ""
	lastEntryCount := 0

	__New() {
		super.__New()
		this.Gui.Opt("+AlwaysOnTop +ToolWindow -SysMenu")
		this.SetVirtualHostNameToFolderMapping("app.local", USER_INTERFACE_PATH, 0) ; block cors error, allow loading local files
		this.Load("http://app.local/index.html")
		this.AddCallbackToScript("Dismiss", (*) => this.Dismiss())
		this.AddCallbackToScript("OpenDashboard", (*) => this.OpenDashboard())

		this.showTimerFn := this._OnShowTimer.Bind(this)

		this._Seed()
		SetTimer(this._Poll.Bind(this), 1000)
	}

	; Positioned near the tray (bottom-right), shown without stealing focus.
	Show() {
		x := A_ScreenWidth - LoggerPopup.WIDTH - 20
		y := A_ScreenHeight - LoggerPopup.HEIGHT - 60
		super.Show(Format("x{} y{} w{} h{} NoActivate", x, y, LoggerPopup.WIDTH, LoggerPopup.HEIGHT), "Logger")
	}

	Dismiss() => this.Hide()

	OpenDashboard() => Run(Paths.dashboards '\Log Dashboard\Log Dashboard.ahk')

	; Reads whatever is already in the log at startup so counts reflect the
	; current session immediately, without treating existing entries as "new".
	_Seed() {
		entries := this._ReadAllEntries()
		for entry in entries {
			this._Count(entry)
		}
		this.lastEntryCount := entries.Length
	}

	_ReadAllEntries() {
		entries := []
		if !FileExist(ErrorLogFile())
			return entries
		for line in StrSplit(FileRead(ErrorLogFile(), "UTF-8"), "`n", "`r") {
			if (Trim(line) = "")
				continue
			try entries.Push(JSON.parse(line))
		}
		return entries
	}

	_Count(entry) {
		severity := entry.Has("severity") ? entry["severity"] : "info"
		if !this.counts.Has(severity)
			this.counts[severity] := 0
		this.counts[severity] += 1
	}

	_Poll() {
		entries := this._ReadAllEntries()

		if (entries.Length = this.lastEntryCount)
			return

		if (entries.Length < this.lastEntryCount) {
			; Logs\errors.log was cleared/rotated (e.g. RunStartup's ClearErrorLog) - start fresh.
			this.counts := Map("info", 0, "warning", 0, "error", 0)
			this.lastEntryCount := 0
		}

		loop entries.Length - this.lastEntryCount {
			entry := entries[this.lastEntryCount + A_Index]
			this._Count(entry)
			this.latestEntry := entry
		}
		this.lastEntryCount := entries.Length

		this._PushCounts()
		SetTimer(this.showTimerFn, 0) ; cancel any pending show
		SetTimer(this.showTimerFn, -LoggerPopup.SHOW_DELAY) ; ...and restart the debounce
	}

	_OnShowTimer() {
		this._PushLatest()
		this.Show()
	}

	_PushCounts() => this.ExecuteScript("window.updateCounts(" JSON.Dump(this.counts) ")")

	_PushLatest() {
		if !this.latestEntry
			return
		severity := this.latestEntry.Has("severity") ? this.latestEntry["severity"] : "info"
		payload := Map(
			"script", this.latestEntry.Has("script") ? this.latestEntry["script"] : "",
			"message", this.latestEntry.Has("message") ? this.latestEntry["message"] : ""
		)
		this.ExecuteScript("window.expandRow('" severity "', " JSON.Dump(payload) ")")
	}
}
