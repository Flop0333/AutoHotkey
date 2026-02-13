/**
 * Fast clipboard send, keeps clipboard unless specified otherwise
 * @param toSend *String* The text you want to send
 * @param endChar *String* The ending character you want after the text you send
 * @param revertClipboard *Boolean* Set false for text to become clipboard
 * @param untilRevert *Integer* Time (ms) to wait before restoring the clipboard. Too short may revert before paste completes; adjust for slow apps.
 */

ClipSend(toSend, endChar := "", revertClipboard := true, untilRevert := 300) {
	if revertClipboard
		prevClip := ClipboardAll()
	A_Clipboard := ""
	toSend .= " "
	A_Clipboard := toSend endChar
	ClipWait(1)
	Send("{Shift Down}{Insert}{Shift Up}")
	if revertClipboard
		SetTimer(() => A_Clipboard := prevClip, -untilRevert)
}
