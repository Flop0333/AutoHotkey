#Include ..\..\Lib\Core.ahk
#Include ..\..\Dashboards\Log Dashboard\Log Dashboard.ahk

; The resident notification host uses a native GUI. The full dashboard remains
; WebView-based and starts only when requested.
Class LoggerPopup {
	static WIN_TITLE := "AutoHotkey Logger"
	static WIDTH := 290
	static MIN_HEIGHT := 34
	static MARGIN := 7
	static Y_POS_MARGIN := 50 + LoggerPopup.MARGIN
	static VISIBLE_DURATION := 5000
	static SEVERITIES := ["info", "warning", "error"]
	static COLORS := Map("info", "3794FF", "warning", "FF9800", "error", "F14C4C")
	static LABELS := Map("info", ["Info", "Infos"], "warning", ["Warning", "Warnings"], "error", ["Error", "Errors"])

	counts := Map("info", 0, "warning", 0, "error", 0)
	lastEntryCount := 0
	isOpen := false
	activeSeverities := Map("info", false, "warning", false, "error", false)
	hideTimerFns := Map()
	rows := Map()

	__New() {
		this.Gui := Gui("+AlwaysOnTop +ToolWindow -SysMenu -Caption", LoggerPopup.WIN_TITLE)
		this.Gui.BackColor := "1E1E1E"
		this.Gui.MarginX := 10
		this.Gui.MarginY := 8
		this.Gui.SetFont("s9 c0B6623", "Segoe UI")
		header := this.Gui.AddText("x10 y8 w270 h18", "AutoHotkey")
		this._BindControl(header)

		y := 30
		for severity in ["error", "warning", "info"] {
			this.Gui.SetFont("s8 c" LoggerPopup.COLORS[severity], "Segoe UI")
			label := this.Gui.AddText("x10 y" y " w270 h20 Hidden", "")
			this.Gui.SetFont("s7 c888888", "Segoe UI")
			script := this.Gui.AddText("x26 y" (y + 20) " w250 h16 Hidden", "")
			this.Gui.SetFont("s7 cDDDDDD", "Segoe UI")
			message := this.Gui.AddText("x26 y" (y + 36) " w250 h18 Hidden", "")
			for control in [label, script, message]
				this._BindControl(control)
			this.rows[severity] := Map("label", label, "script", script, "message", message)
			y += 56
			this.hideTimerFns[severity] := this._OnSeverityTimeout.Bind(this, severity)
		}

		this.Gui.OnEvent("ContextMenu", (*) => this.Dismiss())
		this.InitializeHidden()
		this._Seed()
		this._Poll()
		SetTimer(this._Poll.Bind(this), 1000)
	}

	_BindControl(control) => control.OnEvent("Click", (*) => this.OpenDashboard())

	Show() {
		height := this._Render()
		x := A_ScreenWidth - LoggerPopup.WIDTH - LoggerPopup.MARGIN
		y := A_ScreenHeight - height - LoggerPopup.Y_POS_MARGIN
		this.Gui.Show(Format("x{} y{} w{} h{} NoActivate", x, y, LoggerPopup.WIDTH, height))
		this.isOpen := true
	}

	Hide() {
		this.Gui.Hide()
		this.isOpen := false
	}

	InitializeHidden() {
		x := A_ScreenWidth - LoggerPopup.WIDTH - LoggerPopup.MARGIN
		y := A_ScreenHeight - LoggerPopup.MIN_HEIGHT - LoggerPopup.Y_POS_MARGIN
		this.Gui.Show(Format("Hide x{} y{} w{} h{}", x, y, LoggerPopup.WIDTH, LoggerPopup.MIN_HEIGHT))
		this.isOpen := false
	}

	Dismiss() {
		MarkAllLogsRead()
		for severity in LoggerPopup.SEVERITIES {
			SetTimer(this.hideTimerFns[severity], 0)
			this.activeSeverities[severity] := false
		}
		this.counts := Map("info", 0, "warning", 0, "error", 0)
		this._Render()
		this.Hide()
	}

	OpenDashboard() {
		this.Dismiss()
		ShowLogDashboard()
	}

	_Seed() {
		entries := ReadLogEntries()
		this._RefreshUnreadCounts(entries)
		this.lastEntryCount := Min(GetReadLogEntryCount(), entries.Length)
	}

	_ReadAllEntries() => ReadLogEntries()

	_RefreshUnreadCounts(entries) {
		this.counts := GetUnreadLogCounts(entries)
	}

	_Poll() {
		entries := this._ReadAllEntries()
		if (entries.Length < this.lastEntryCount)
			this.lastEntryCount := 0

		loop entries.Length - this.lastEntryCount {
			entry := entries[this.lastEntryCount + A_Index]
			if (entry.Has("notify") && entry["notify"])
				this._ShowSeverity(entry.Get("severity", "info"), entry)
		}
		this.lastEntryCount := entries.Length

		this._RefreshUnreadCounts(entries)
		if (GetReadLogEntryCount() >= entries.Length)
			this._HideNotification()
		else
			this._Render()
	}

	_ShowSeverity(severity, entry) {
		if !this.rows.Has(severity)
			return
		this.activeSeverities[severity] := true
		this.rows[severity]["script"].Text := entry.Get("script", "")
		this.rows[severity]["message"].Text := entry.Get("message", "")
		this.Show()
		SetTimer(this.hideTimerFns[severity], 0)
		SetTimer(this.hideTimerFns[severity], -LoggerPopup.VISIBLE_DURATION)
	}

	_HideNotification() {
		for severity in LoggerPopup.SEVERITIES {
			SetTimer(this.hideTimerFns[severity], 0)
			this.activeSeverities[severity] := false
		}
		this._Render()
		this.Hide()
	}

	_OnSeverityTimeout(severity) {
		this.activeSeverities[severity] := false
		for otherSeverity in LoggerPopup.SEVERITIES {
			if this.activeSeverities[otherSeverity] {
				this._Render()
				return
			}
		}
		this._HideNotification()
	}

	_Render() {
		y := 30
		for severity in ["error", "warning", "info"] {
			row := this.rows[severity]
			count := this.counts.Get(severity, 0)
			visible := count > 0
			labels := LoggerPopup.LABELS[severity]
			row["label"].Text := "●  " count " " labels[count = 1 ? 1 : 2]
			row["label"].Visible := visible
			if !visible {
				row["script"].Visible := false
				row["message"].Visible := false
				continue
			}

			row["label"].Move(10, y, 270, 20)
			y += 20
			expanded := this.activeSeverities[severity]
			row["script"].Visible := expanded
			row["message"].Visible := expanded
			if expanded {
				row["script"].Move(26, y, 250, 16)
				row["message"].Move(26, y + 16, 250, 18)
				y += 36
			}
		}
		height := Max(LoggerPopup.MIN_HEIGHT, y + 4)
		if this.isOpen {
			x := A_ScreenWidth - LoggerPopup.WIDTH - LoggerPopup.MARGIN
			windowY := A_ScreenHeight - height - LoggerPopup.Y_POS_MARGIN
			this.Gui.Move(x, windowY, LoggerPopup.WIDTH, height)
		}
		return height
	}
}
