#Include ..\..\Lib\Core.ahk
#Include ..\..\Lib\Core\WebView.ahk

Class LoggerPopup extends WebViewToo {
	static WIDTH := 150
	static HEIGHT := 230
	static VISIBLE_DURATION := 500000 ; ms a severity's detail stays expanded since its last log
	static SEVERITIES := ["info", "warning", "error"]

	counts := Map("info", 0, "warning", 0, "error", 0)
	lastEntryCount := 0
	isOpen := false
	activeSeverities := Map("info", false, "warning", false, "error", false)
	hideTimerFns := Map()

	__New() {
		super.__New()
		this.Gui.Opt("+AlwaysOnTop +ToolWindow -SysMenu")
		this.SetVirtualHostNameToFolderMapping("app.local", USER_INTERFACE_PATH, 0) ; block cors error, allow loading local files
		this.AddCallbackToScript("Dismiss", (*) => this.Dismiss())
		this.AddCallbackToScript("OpenDashboard", (*) => this.OpenDashboard())

		for severity in LoggerPopup.SEVERITIES {
			this.hideTimerFns[severity] := this._OnSeverityTimeout.Bind(this, severity)
		}

		this._Seed()
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
		this.NavigationCompleted((*) => this._OnPageReady())
		this.Load("http://app.local/index.html")
	}

	_OnPageReady() {
		this._PushCounts()
		SetTimer(this._Poll.Bind(this), 1000)
	}

	; Positioned near the tray (bottom-right), shown without stealing focus.
	Show() {
		x := A_ScreenWidth - LoggerPopup.WIDTH - 10
		y := A_ScreenHeight - LoggerPopup.HEIGHT - 50
		super.Show(Format("x{} y{} w{} h{} NoActivate", x, y, LoggerPopup.WIDTH, LoggerPopup.HEIGHT), "Logger")
		this.isOpen := true
	}

	; Dismiss cancels every severity's timer - a right-click closes it outright,
	; rather than leaving a timer running that would silently reopen it.
	Dismiss() {
		for severity in LoggerPopup.SEVERITIES {
			SetTimer(this.hideTimerFns[severity], 0)
			this.activeSeverities[severity] := false
		}
		this.Hide()
		this.isOpen := false
	}

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
			; Plain Log* entries still count toward the totals, but only
			; LogAndNotify* entries (notify=true) should show/expand a row.
			if (entry.Has("notify") && entry["notify"]) {
				severity := entry.Has("severity") ? entry["severity"] : "info"
				this._ShowSeverity(severity, entry)
			}
		}
		this.lastEntryCount := entries.Length

		this._PushCounts()
	}

	; Expands (or re-expands) one severity's row with its latest entry, opens
	; the popup if it was closed, and (re)starts that severity's own 5s timer.
	_ShowSeverity(severity, entry) {
		this.activeSeverities[severity] := true
		if !this.isOpen
			this.Show()

		payload := Map(
			"script", entry.Has("script") ? entry["script"] : "",
			"message", entry.Has("message") ? entry["message"] : ""
		)
		this.ExecuteScript("window.expandRow('" severity "', " JSON.Dump(payload) ")")

		SetTimer(this.hideTimerFns[severity], 0) ; cancel any pending hide for this severity
		SetTimer(this.hideTimerFns[severity], -LoggerPopup.VISIBLE_DURATION) ; ...and restart it
	}

	; Fires 5s after the last log for this severity: collapse just that row,
	; then close the whole popup once no severity is showing anymore.
	_OnSeverityTimeout(severity) {
		this.activeSeverities[severity] := false
		this.ExecuteScript("window.collapseRow('" severity "')")

		for sev in LoggerPopup.SEVERITIES {
			if this.activeSeverities[sev]
				return ; something else is still showing - keep the popup open
		}
		this.Hide()
		this.isOpen := false
	}

	_PushCounts() => this.ExecuteScript("window.updateCounts(" JSON.Dump(this.counts) ")")
}
