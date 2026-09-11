#Include ..\..\Lib\Core\Paths.ahk
#Include ..\..\Lib\Tools\Gdip\Gdip_All.ahk

; Paints the Logger popup in the Control Deck's retro style onto a per-pixel
; alpha layered window. Artwork comes from the Control Deck's asset folder so
; both surfaces stay one visual family. Layout values are 96-DPI units; the
; world transform scales them to the primary monitor's DPI.
Class LoggerPopupRenderer {
	static ASSETS := Paths.dashboards "\Control Deck\User Interface\assets\control-deck\"
	static IMAGES := ["panel-plate.png", "background-tile.png", "screen-texture.png", "window-close.png",
		"action-notify-error.png", "action-notify-warning.png", "action-notify-info.png"]
	static ICONS := Map("error", "action-notify-error.png", "warning", "action-notify-warning.png", "info", "action-notify-info.png")

	static WIDTH := 330
	static FRAME := 18          ; Panel-plate border width, drawn from the same 44 px slice as the Control Deck cards.
	static FRAME_SLICE := 44
	static INSET := 22
	static SHADOW := 4          ; Hard offset shadow, matching the Control Deck's --shadow-hard.
	static HEADER_HEIGHT := 26
	static ROW_HEIGHT := 30
	static DETAIL_HEIGHT := 36  ; Added below the title when a row shows its latest entry.
	static ROW_GAP := 6
	static SCREEN_MARGIN := 10
	static CLOSE_SIZE := 14

	; The Control Deck palette (styles.css :root) as ARGB.
	static COLORS := Map(
		"shadow", 0x99090807,
		"shade", 0xC7090807,
		"pill", 0xC0090807,
		"screen", 0xF2070605,
		"oxblood", 0xFF5A191D,
		"red", 0xFF8E2C31,
		"brass", 0xFFD0A05A,
		"text", 0xFFD8C6A5,
		"muted", 0xFFA49378,
		"neutral", 0xFF786B5C,
		"error", 0xFFC94F4F,
		"warning", 0xFFD9A13B,
		"info", 0xFF6FA3D8
	)

	images := Map()
	imageSizes := Map()
	families := []
	closeBounds := [0, 0, 0, 0]

	__New() {
		this.token := Gdip_Startup()
		this.scale := A_ScreenDPI / 96
		for name in LoggerPopupRenderer.IMAGES {
			bitmap := Gdip_CreateBitmapFromFile(LoggerPopupRenderer.ASSETS name)
			if !bitmap
				continue
			this.images[name] := bitmap
			this.imageSizes[name] := [Gdip_GetImageWidth(bitmap), Gdip_GetImageHeight(bitmap)]
		}

		; Clamp edge sampling so stretched frame slices do not bleed neighbouring pixels.
		DllCall("gdiplus\GdipCreateImageAttributes", "Ptr*", &attributes := 0)
		DllCall("gdiplus\GdipSetImageAttributesWrapMode", "Ptr", attributes, "Int", 3, "UInt", 0, "Int", 0)
		this.imageAttributes := attributes

		this.fonts := Map(
			"title", this._CreateFont(12, false),
			"label", this._CreateFont(11, true),
			"tag", this._CreateFont(9, true),
			"script", this._CreateFont(10, false),
			"message", this._CreateFont(11, false)
		)
		this.formats := [this._CreateFormat(0), this._CreateFormat(1)]
		this.backgroundBrush := this._CreateBackgroundBrush()
	}

	; Draws rows onto the window at the bottom-right of the primary work area.
	; Each row is a Map of severity, label, expanded, script, and message.
	; Returns the window geometry in physical pixels.
	Paint(hwnd, rows) {
		R := LoggerPopupRenderer
		logicalHeight := this._MeasureHeight(rows)
		width := Ceil((R.WIDTH + R.SHADOW) * this.scale)
		height := Ceil((logicalHeight + R.SHADOW) * this.scale)
		MonitorGetWorkArea(MonitorGetPrimary(), , , &right, &bottom)
		x := right - width - Round(R.SCREEN_MARGIN * this.scale)
		y := bottom - height - Round(R.SCREEN_MARGIN * this.scale)

		hbm := CreateDIBSection(width, height)
		hdc := CreateCompatibleDC()
		obm := SelectObject(hdc, hbm)
		G := Gdip_GraphicsFromHDC(hdc)
		try {
			Gdip_SetInterpolationMode(G, 7)     ; HighQualityBicubic
			DllCall("gdiplus\GdipSetPixelOffsetMode", "Ptr", G, "Int", 2)
			Gdip_SetSmoothingMode(G, 3)         ; None: keep rectangles on the pixel grid
			Gdip_SetTextRenderingHint(G, 3)     ; AntiAliasGridFit stays correct on an alpha surface
			DllCall("gdiplus\GdipScaleWorldTransform", "Ptr", G, "Float", this.scale, "Float", this.scale, "Int", 0)
			this._Draw(G, rows, logicalHeight)
			UpdateLayeredWindow(hwnd, hdc, x, y, width, height)
		} finally {
			Gdip_DeleteGraphics(G)
			SelectObject(hdc, obm)
			DeleteObject(hbm)
			DeleteDC(hdc)
		}
		return {x: x, y: y, w: width, h: height}
	}

	; Hit-tests client coordinates (physical pixels) against the close glyph.
	IsCloseHit(x, y) {
		bounds := this.closeBounds
		return x >= bounds[1] && x <= bounds[3] && y >= bounds[2] && y <= bounds[4]
	}

	_MeasureHeight(rows) {
		R := LoggerPopupRenderer
		height := R.INSET - 4 + R.HEADER_HEIGHT + 8
		if !rows.Length
			height += R.ROW_HEIGHT + R.ROW_GAP
		for row in rows
			height += R.ROW_HEIGHT + (row["expanded"] ? R.DETAIL_HEIGHT : 0) + R.ROW_GAP
		return height + R.INSET - 4
	}

	_Draw(G, rows, height) {
		R := LoggerPopupRenderer
		C := R.COLORS
		width := R.WIDTH
		this._Fill(G, C["shadow"], R.SHADOW, R.SHADOW, width, height)
		if this.backgroundBrush
			Gdip_FillRectangle(G, this.backgroundBrush, R.FRAME // 2, R.FRAME // 2, width - R.FRAME, height - R.FRAME)
		else
			this._Fill(G, C["screen"], R.FRAME // 2, R.FRAME // 2, width - R.FRAME, height - R.FRAME)
		this._DrawFrame(G, width, height)

		left := R.INSET
		contentWidth := width - 2 * R.INSET
		y := R.INSET - 4
		this._DrawHeader(G, left, y, contentWidth)
		y += R.HEADER_HEIGHT
		this._Fill(G, C["oxblood"], left, y + 1, contentWidth, 1)
		this._Fill(G, C["red"], left, y, 24, 3)
		y += 8

		if !rows.Length {
			this._Text(G, "NO UNREAD ENTRIES", "label", C["neutral"], left, y, contentWidth, R.ROW_HEIGHT, 1)
			y += R.ROW_HEIGHT + R.ROW_GAP
		}
		for row in rows
			y := this._DrawRow(G, row, left, y, contentWidth) + R.ROW_GAP
	}

	_DrawHeader(G, x, y, width) {
		R := LoggerPopupRenderer
		this._Text(G, "AutoHotkey", "title", R.COLORS["brass"], x, y, width - R.CLOSE_SIZE, R.HEADER_HEIGHT)

		size := R.CLOSE_SIZE
		closeX := x + width - size
		closeY := y + (R.HEADER_HEIGHT - size) // 2
		this._Image(G, "window-close.png", closeX, closeY, size, size)
		pad := 6
		this.closeBounds := [(closeX - pad) * this.scale, (closeY - pad) * this.scale,
			(closeX + size + pad) * this.scale, (closeY + size + pad) * this.scale]
	}

	; A Control Deck pill that, when expanded, grows to hold the latest entry
	; inside the same border, aligned under the title.
	_DrawRow(G, row, x, y, width) {
		R := LoggerPopupRenderer
		C := R.COLORS
		severity := row["severity"]
		color := C[severity]
		height := R.ROW_HEIGHT + (row["expanded"] ? R.DETAIL_HEIGHT : 0)

		this._Fill(G, C["pill"], x, y, width, height)
		this._Outline(G, (color & 0x00FFFFFF) | 0x73000000, x, y, width, height)
		if row["expanded"] {
			detailY := y + R.ROW_HEIGHT - 4
			this._Text(G, row["script"], "script", C["muted"], x + 34, detailY, width - 40, 16)
			this._Text(G, "> " row["message"], "message", C["text"], x + 34, detailY + 16, width - 40, 18)

			this._Fill(G, color, x + width - 42, y + 12, 6, 6)
			this._Text(G, "NEW", "tag", color, x + width - 32, y, 28, R.ROW_HEIGHT)
		}
		this._Image(G, R.ICONS[severity], x + 5, y + 4, 22, 22)
		this._Text(G, row["label"], "label", color, x + 34, y, width - 90, R.ROW_HEIGHT)
		return y + height
	}

	; Nine-slice of the Control Deck panel plate; its centre stays open so the
	; tiled deck background shows through, as it does behind the dashboard.
	_DrawFrame(G, width, height) {
		name := "panel-plate.png"
		if !this.images.Has(name)
			return
		S := LoggerPopupRenderer.FRAME_SLICE
		F := LoggerPopupRenderer.FRAME
		sourceWidth := this.imageSizes[name][1]
		sourceHeight := this.imageSizes[name][2]
		this._Image(G, name, 0, 0, F, F, 0, 0, S, S)
		this._Image(G, name, width - F, 0, F, F, sourceWidth - S, 0, S, S)
		this._Image(G, name, 0, height - F, F, F, 0, sourceHeight - S, S, S)
		this._Image(G, name, width - F, height - F, F, F, sourceWidth - S, sourceHeight - S, S, S)
		this._Image(G, name, F, 0, width - 2 * F, F, S, 0, sourceWidth - 2 * S, S)
		this._Image(G, name, F, height - F, width - 2 * F, F, S, sourceHeight - S, sourceWidth - 2 * S, S)
		this._Image(G, name, 0, F, F, height - 2 * F, 0, S, S, sourceHeight - 2 * S)
		this._Image(G, name, width - F, F, F, height - 2 * F, sourceWidth - S, S, S, sourceHeight - 2 * S)
	}

	; Bakes the deck's background tile, its dark overlay, and the scanline
	; texture into one tile so each paint is a single texture fill.
	_CreateBackgroundBrush() {
		if !this.images.Has("background-tile.png")
			return 0
		size := this.imageSizes["background-tile.png"]
		baked := Gdip_CreateBitmap(size[1], size[2])
		G := Gdip_GraphicsFromImage(baked)
		Gdip_DrawImage(G, this.images["background-tile.png"], 0, 0, size[1], size[2])
		this._Fill(G, LoggerPopupRenderer.COLORS["shade"], 0, 0, size[1], size[2])
		if this.images.Has("screen-texture.png")
			Gdip_DrawImage(G, this.images["screen-texture.png"], 0, 0, size[1], size[2], , , , , 0.2)
		Gdip_DeleteGraphics(G)
		this.backgroundBitmap := baked
		return Gdip_CreateTextureBrush(baked, 0)
	}

	_CreateFont(size, bold) {
		for familyName in ["Cascadia Mono", "Consolas", "Courier New"] {
			if !family := Gdip_FontFamilyCreate(familyName)
				continue
			this.families.Push(family)
			for style in (bold ? [1, 0] : [0])
				if font := Gdip_FontCreate(family, size, style)
					return font
		}
		return 0
	}

	; Single-line, vertically centred, and trimmed with an ellipsis.
	_CreateFormat(align) {
		format := Gdip_StringFormatCreate(0x1000)
		Gdip_SetStringFormatAlign(format, align)
		DllCall("gdiplus\GdipSetStringFormatLineAlign", "Ptr", format, "Int", 1)
		DllCall("gdiplus\GdipSetStringFormatTrimming", "Ptr", format, "Int", 3)
		return format
	}

	_Text(G, text, font, argb, x, y, width, height, align := 0) {
		CreateRectF(&rect, x, y, width, height)
		brush := Gdip_BrushCreateSolid(argb)
		Gdip_DrawString(G, text, this.fonts[font], this.formats[align + 1], brush, &rect)
		Gdip_DeleteBrush(brush)
	}

	_Image(G, name, dx, dy, dw, dh, sx := 0, sy := 0, sw := "", sh := "") {
		if !this.images.Has(name)
			return
		size := this.imageSizes[name]
		DllCall("gdiplus\GdipDrawImageRectRect", "Ptr", G, "Ptr", this.images[name],
			"Float", dx, "Float", dy, "Float", dw, "Float", dh,
			"Float", sx, "Float", sy, "Float", sw = "" ? size[1] : sw, "Float", sh = "" ? size[2] : sh,
			"Int", 2, "Ptr", this.imageAttributes, "Ptr", 0, "Ptr", 0)
	}

	_Fill(G, argb, x, y, width, height) {
		brush := Gdip_BrushCreateSolid(argb)
		Gdip_FillRectangle(G, brush, x, y, width, height)
		Gdip_DeleteBrush(brush)
	}

	_Outline(G, argb, x, y, width, height) {
		brush := Gdip_BrushCreateSolid(argb)
		Gdip_FillRectangle(G, brush, x, y, width, 1)
		Gdip_FillRectangle(G, brush, x, y + height - 1, width, 1)
		Gdip_FillRectangle(G, brush, x, y + 1, 1, height - 2)
		Gdip_FillRectangle(G, brush, x + width - 1, y + 1, 1, height - 2)
		Gdip_DeleteBrush(brush)
	}
}
