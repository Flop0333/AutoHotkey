; ============================================================================
; Logging - Public facade for the shared logger and control deck
; ============================================================================
;
; Startup calls InitializeLogging() exactly once per suite start. Other scripts
; include this file to use Log*, LogAndNotify*, Show/HideLogger, and
; Show/HideControlDeck without creating their own UI instances.

#Include ..\..\Lib\Core\OnError.ahk
#Include Logger.ahk
#Include ..\Control Deck\Control Deck.ahk

InitializeLogging() {
	return Map("logger", EnsureLoggerRunning())
}

; The popup is the only logging UI that must stay resident. Reuse an existing
; host across suite reloads; the dashboard starts lazily from ShowControlDeck().
EnsureLoggerRunning() {
	if loggerWindow := FindLoggerWindow()
		return loggerWindow

	StartLogger()
	if loggerWindow := WaitForLoggerWindow()
		return loggerWindow

	throw Error("Failed to initialize the Logger host")
}
