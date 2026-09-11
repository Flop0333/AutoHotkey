#Include ..\..\Lib\Core\OnError.ahk
#Include ..\..\Lib\Tools\Info.ahk
#Include Logger.ahk
#Include Popup Renderer.ahk
#Include ..\..\Dashboards\Control Deck\Control Deck.ahk

; The resident notification host is a native layered window painted in the
; Control Deck style. The full WebView dashboard starts only when requested.
Class LoggerPopup {
	static VISIBLE_DURATION := 5000
	static SEVERITIES := ["info", "warning", "error"]
	static DISPLAY_ORDER := ["error", "warning", "info"]

	counts := Map("info", 0, "warning", 0, "error", 0)
	lastEntryCount := 0
	logSessionId := ""
	isOpen := false
	activeSeverities := Map("info", false, "warning", false, "error", false)
	latestEntries := Map()
	hideTimerFns := Map()
	renderedState := ""
	geometry := {x: 0, y: 0, w: 0, h: 0}

	__New() {
		this.renderer := LoggerPopupRenderer()
		this.Gui := Gui("+AlwaysOnTop +ToolWindow -SysMenu -Caption -DPIScale +E0x80000", LoggerWindowTitle())
		for severity in LoggerPopup.SEVERITIES {
			this.latestEntries[severity] := Map("script", "", "message", "")
			this.hideTimerFns[severity] := this._OnSeverityTimeout.Bind(this, severity)
		}

		OnMessage(0x0202, this._OnLeftButtonUp.Bind(this))   ; WM_LBUTTONUP
		OnMessage(0x0205, this._OnRightButtonUp.Bind(this))  ; WM_RBUTTONUP
		OnMessage(0x0020, this._OnSetCursor.Bind(this))      ; WM_SETCURSOR
		this._Seed()
		this._Render()
		this._Poll()
		SetTimer(this._Poll.Bind(this), 1000)
	}

	Show() {
		this._Render()
		g := this.geometry
		if !this.isOpen
			this.Gui.Show(Format("x{} y{} w{} h{} NoActivate", g.x, g.y, g.w, g.h))
		this.isOpen := true
	}

	Hide() {
		this.Gui.Hide()
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
		ShowControlDeck("logs")
	}

	_OnLeftButtonUp(wParam, lParam, msg, hwnd) {
		if (hwnd != this.Gui.Hwnd)
			return
		if this.renderer.IsCloseHit(lParam & 0xFFFF, (lParam >> 16) & 0xFFFF)
			this.Dismiss()
		else
			this.OpenDashboard()
		return 0
	}

	_OnRightButtonUp(wParam, lParam, msg, hwnd) {
		if (hwnd != this.Gui.Hwnd)
			return
		this.Dismiss()
		return 0
	}

	_OnSetCursor(wParam, lParam, msg, hwnd) {
		if (hwnd != this.Gui.Hwnd || (lParam & 0xFFFF) != 1)  ; HTCLIENT
			return
		DllCall("SetCursor", "Ptr", DllCall("LoadCursor", "Ptr", 0, "Ptr", 32649, "Ptr"))  ; IDC_HAND
		return true
	}

	_Seed() {
		state := ReadLogState()
		entries := state["entries"]
		this._RefreshUnreadCounts(entries, state["readEntryCount"])
		this.lastEntryCount := Min(state["readEntryCount"], entries.Length)
		this.logSessionId := state["sessionId"]
	}

	_RefreshUnreadCounts(entries, readEntryCount) {
		this.counts := GetUnreadLogCounts(entries, readEntryCount)
	}

	_Poll() {
		state := ReadLogState()
		entries := state["entries"]
		currentSessionId := state["sessionId"]
		if (currentSessionId != this.logSessionId) {
			this.lastEntryCount := 0
			this.logSessionId := currentSessionId
		} else if (entries.Length < this.lastEntryCount) {
			; Retain a defensive fallback for external/manual log truncation.
			this.lastEntryCount := 0
		}

		loop entries.Length - this.lastEntryCount {
			entry := entries[this.lastEntryCount + A_Index]
			if (entry.Has("notify") && entry["notify"])
				this._ShowSeverity(entry.Get("severity", "info"), entry)
		}
		this.lastEntryCount := entries.Length

		this._RefreshUnreadCounts(entries, state["readEntryCount"])
		if (state["readEntryCount"] >= entries.Length)
			this._HideNotification()
		else
			this._Render()
	}

	_ShowSeverity(severity, entry) {
		if !this.latestEntries.Has(severity)
			return
		this.activeSeverities[severity] := true
		this.latestEntries[severity] := Map(
			"script", entry.Get("script", ""),
			"message", Trim(RegExReplace(entry.Get("message", ""), "\s+", " "))
		)
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

	; Repaints only when the visible content changes; the poll runs every second.
	_Render() {
		rows := []
		state := ""
		for severity in LoggerPopup.DISPLAY_ORDER {
			count := this.counts.Get(severity, 0)
			if (count < 1)
				continue
			expanded := this.activeSeverities[severity]
			latest := this.latestEntries[severity]
			rows.Push(Map("severity", severity, "label", count " " severity, "expanded", expanded,
				"script", latest["script"], "message", latest["message"]))
			state .= severity count expanded (expanded ? latest["script"] latest["message"] : "") "`n"
		}
		if (state == this.renderedState && this.geometry.w)
			return
		this.renderedState := state
		this.geometry := this.renderer.Paint(this.Gui.Hwnd, rows)
	}
}
