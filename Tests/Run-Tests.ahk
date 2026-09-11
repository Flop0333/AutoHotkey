; ============================================================================
; Run-Tests - Manually kicks off the full test suite and opens the dashboard
; ============================================================================
;
; Runs the syntax check, unit tests, and integration tests in the background
; (Tests\Invoke-AllTests.ps1) and opens the Control Deck Tests section.
; progress and review pass/fail results as they land. Double-click this file,
; or run it with AutoHotkey64.exe, whenever you want a manual test run.
; ============================================================================

#Requires AutoHotkey v2
#SingleInstance Force

#Include ..\Dashboards\Control Deck\Control Deck.ahk

ShowControlDeck("tests")
Run('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' Paths.autohotkey '\Tests\Invoke-AllTests.ps1' '"', , "Hide")
ExitApp()
