; ============================================================================
; Run-Tests - Manually kicks off the full test suite and opens the dashboard
; ============================================================================
;
; Runs the syntax check, unit tests, and integration tests in the background
; (Tests\Invoke-AllTests.ps1) and opens the Test Dashboard so you can watch
; progress and review pass/fail results as they land. Double-click this file,
; or run it with AutoHotkey64.exe, whenever you want a manual test run.
; ============================================================================

#Requires AutoHotkey v2
#SingleInstance Force

#Include ..\Dashboards\Test Dashboard\Test Dashboard.ahk

ShowTestDashboard()
Run('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' TestDashboard.RUNNER_SCRIPT '"', , "Hide")
ExitApp()
