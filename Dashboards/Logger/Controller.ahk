#Include ..\..\Lib\Core.ahk
#Include ..\..\Lib\Core\WebView.ahk
#Include ..\..\Dashboards\Log Dashboard\Log Dashboard.ahk

Class LoggerPopup extends WebViewToo {
	static WIN_TITLE := "AutoHotkey Logger"
	static WIDTH := 280
	static HEIGHT := 230
	static MIN_HEIGHT := 34
	static VISIBLE_DURATION := 5000 ; ms a severity's detail stays expanded since its last log
	static SEVERITIES := ["info", "warning", "error"]

	counts := Map("info", 0, "warning", 0, "error", 0)
	lastEntryCount := 0
	isOpen := false
	currentHeight := LoggerPopup.HEIGHT
	activeSeverities := Map("info", false, "warning", false, "error", false)
	hideTimerFns := Map()

	__New() {
		TraySetIcon "..\..\Lib\icon.png"
		super.__New()
		this.Gui.Title := LoggerPopup.WIN_TITLE
		this.Gui.Opt("+AlwaysOnTop +ToolWindow -SysMenu")
		this.SetVirtualHostNameToFolderMapping("app.local", Paths.dashboards "\Logger\User Interface", 0) ; block cors error, allow loading local files
		this.Load("http://app.local/index.html")
		this.AddCallbackToScript("Dismiss", (*) => this.Dismiss())
		this.AddCallbackToScript("OpenDashboard", (*) => this.OpenDashboard())
		this.AddCallbackToScript("Resize", (webview, height) => this.ResizeToContent(height))

		for severity in LoggerPopup.SEVERITIES {
			this.hideTimerFns[severity] := this._OnSeverityTimeout.Bind(this, severity)
		}

		this._Seed()
		this.InitializeHidden()
		; Don't start polling until the page has actually finished loading -
		; window.updateCounts/expandRow don't exist before then, so an
		; ExecuteScript() call that races the navigation fails silently and
		; is never retried. That's not just _Seed()'s initial push: _Poll()
		; itself could win that same race on its very first tick if something
		; gets logged within the first moment after construction, which is
		; exactly what happens at startup - leaving the popup stuck showing
		; the page's default 0/0/0 until an unrelated later log event
		; happened to succeed. Deferring the whole poll loop, not just the
		; first push, closes the race for every ExecuteScript call, not just this one.
		this._PushState()
		SetTimer(this._Poll.Bind(this), 1000)
	}

	_OnPageReady() {
		this._PushState()
		SetTimer(this._Poll.Bind(this), 1000)
	}

	; Positioned near the tray (bottom-right), shown without stealing focus.
	Show() {
		x := A_ScreenWidth - LoggerPopup.WIDTH - 10
		y := A_ScreenHeight - this.currentHeight - 50
		super.Show(Format("x{} y{} w{} h{} NoActivate", x, y, LoggerPopup.WIDTH, this.currentHeight), LoggerPopup.WIN_TITLE)
		this.isOpen := true
	}

	InitializeHidden() {
		x := A_ScreenWidth - LoggerPopup.WIDTH - 10
		y := A_ScreenHeight - LoggerPopup.HEIGHT - 50
		super.Show(Format("Hide x{} y{} w{} h{} NoActivate", x, y, LoggerPopup.WIDTH, LoggerPopup.HEIGHT), LoggerPopup.WIN_TITLE)
		this.isOpen := false
	}

	ResizeToContent(height) {
		this.currentHeight := Max(LoggerPopup.MIN_HEIGHT, Round(height))
		x := A_ScreenWidth - LoggerPopup.WIDTH - 10
		y := A_ScreenHeight - this.currentHeight - 50
		this.Gui.Move(x, y, LoggerPopup.WIDTH, this.currentHeight)
	}

	; Dismiss cancels every severity's timer - a right-click closes it outright,
	; rather than leaving a timer running that would silently reopen it.
	Dismiss() {
		MarkAllLogsRead()
		for severity in LoggerPopup.SEVERITIES {
			SetTimer(this.hideTimerFns[severity], 0)
			this.activeSeverities[severity] := false
		}
		this.Hide()
		this.isOpen := false
		this.counts := Map("info", 0, "warning", 0, "error", 0)
		this._PushState()
	}

	OpenDashboard() {
		this.Dismiss()
		ShowLogDashboard()
	}

	; Restore unread totals if the logger host is restarted during a session.
	_Seed() {
		entries := this._ReadAllEntries()
		this._RefreshUnreadCounts(entries)
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

	_RefreshUnreadCounts(entries) {
		this.counts := Map("info", 0, "warning", 0, "error", 0)
		readEntryCount := Min(GetReadLogEntryCount(), entries.Length)
		loop entries.Length - readEntryCount
			this._Count(entries[readEntryCount + A_Index])
	}

	_Poll() {
		entries := this._ReadAllEntries()

		if (entries.Length < this.lastEntryCount) {
			; Logs\errors.log was cleared/rotated (e.g. RunStartup's ClearErrorLog) - start fresh.
			this.lastEntryCount := 0
		}

		loop entries.Length - this.lastEntryCount {
			entry := entries[this.lastEntryCount + A_Index]
			if (entry.Has("notify") && entry["notify"]) {
				severity := entry.Has("severity") ? entry["severity"] : "info"
				this._ShowSeverity(severity, entry)
			}
		}
		this.lastEntryCount := entries.Length

		this._RefreshUnreadCounts(entries)
		if (GetReadLogEntryCount() >= entries.Length)
			this._HideNotification()
		this._PushState()
	}

	_HideNotification() {
		for severity in LoggerPopup.SEVERITIES {
			SetTimer(this.hideTimerFns[severity], 0)
			this.activeSeverities[severity] := false
			this.ExecuteScript("window.collapseRow('" severity "')")
		}
		this.Hide()
		this.isOpen := false
	}

	; Expands (or re-expands) one severity's row with its latest entry, opens
	; the popup if it was closed, and (re)starts that severity's own 5s timer.
	_ShowSeverity(severity, entry) {
		this.activeSeverities[severity] := true
		this.Show()

		payload := Map(
			"script", entry.Has("script") ? entry["script"] : "",
			"message", entry.Has("message") ? entry["message"] : ""
		)
		this.ExecuteScript("window.expandRow('" severity "', " JSON.Dump(payload) ")")

		SetTimer(this.hideTimerFns[severity], 0) ; cancel any pending hide for this severity
		SetTimer(this.hideTimerFns[severity], -LoggerPopup.VISIBLE_DURATION) ; ...and restart it
	}

	; Fires 5s after the last log for this severity. Keep every displayed detail
	; expanded until the final severity timer has expired, then close them all.
	_OnSeverityTimeout(severity) {
		this.activeSeverities[severity] := false

		for sev in LoggerPopup.SEVERITIES {
			if this.activeSeverities[sev]
				return
		}

		this._HideNotification()
	}

	_PushState() => this.ExecuteScript("window.updateCounts(" JSON.Dump(this.counts) ")")
}
