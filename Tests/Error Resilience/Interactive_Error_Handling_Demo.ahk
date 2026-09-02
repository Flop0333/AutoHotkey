#Requires AutoHotkey v2
#SingleInstance Force
#Warn All

#Include ..\..\Lib\Core\SafeCall.ahk
#Include ..\..\Lib\Core\Notifier.ahk

/** Interactive, isolated demonstration of the error-resilience components. */
class InteractiveErrorHandlingDemo {
    static passed := 0
    static failed := 0
    static originalLocalAppData := ""
    static testRoot := A_Temp "\AutoHotkey Error Demo " A_Now "-" A_TickCount

    static Run() {
        this.originalLocalAppData := EnvGet("LOCALAPPDATA")
        EnvSet("LOCALAPPDATA", this.testRoot)

        try {
            MsgBox(
                "This demo intentionally causes several errors. They should be caught, logged, "
                "and followed by another test instead of stopping the script.`n`n"
                "Each test has its own PASS/FAIL MsgBox.`n`n"
                "Isolated log folder:`n" ErrorReporter.GetLogDir(),
                "Error handling demo",
                "Iconi"
            )

            this.TestErrorRecord()
            this.TestNonErrorThrownValue()
            this.TestDirectReporting()
            this.TestRedaction()
            this.TestSafeCallSuccess()
            this.TestSafeCallFailure()
            this.TestCallbackArgumentForwarding()
            this.TestTimerFailure()
            this.TestGuiFailure()
            this.TestNotification()
            this.TestRotation()
            this.TestFallbackReporting()

            logDir := ErrorReporter.GetLogDir()
            summary := (
                "Completed " (this.passed + this.failed) " checks.`n`n"
                "Passed: " this.passed "`n"
                "Failed: " this.failed "`n`n"
                "Important current limitation:`n"
                "There is no suite-wide OnError handler yet. An error outside SafeCall or a "
                "SafeCallback wrapper can still show AutoHotkey's normal error dialog and stop that thread.`n`n"
                "Demo logs:`n" logDir "`n`n"
                "Open the demo log folder now?"
            )

            if MsgBox(summary, "Demo complete", "YesNo " (this.failed ? "Icon!" : "Iconi")) = "Yes"
                Run(logDir)
        } catch Any as demoError {
            demoRecord := ErrorRecord.FromThrown(demoError)
            MsgBox(
                "The demo harness itself failed.`n`n"
                "Type: " demoRecord.errorType "`n"
                "Message: " demoRecord.errorMessage "`n"
                "Line: " demoRecord.line,
                "Demo harness error",
                "Iconx"
            )
        } finally {
            EnvSet("LOCALAPPDATA", this.originalLocalAppData)
        }
    }

    static TestErrorRecord() {
        this.Before("1. ErrorRecord", "Create structured diagnostic data from a normal Error object.")
        sourceError := Error("Intentional ErrorRecord demonstration")
        record := ErrorRecord.FromThrown(sourceError, "ErrorRecord demonstration failed")
        ok := record.errorType = "Error"
            && record.errorMessage = sourceError.Message
            && record.message = "ErrorRecord demonstration failed"
            && StrLen(record.fingerprint) = 8
        this.Check(ok, "ErrorRecord captured the Error", "Fingerprint: " record.fingerprint "`n`nJSON:`n" record.ToJson())
    }

    static TestNonErrorThrownValue() {
        this.Before("2. Non-Error thrown value", "Throw a plain string and normalize it into an ErrorRecord.")
        caughtValue := ""
        try
            throw "intentional plain-string failure"
        catch Any as thrownValue
            caughtValue := thrownValue

        record := ErrorRecord.FromThrown(caughtValue, "Plain-string demonstration failed")
        ok := record.errorType = "String" && record.errorMessage = caughtValue
        this.Check(ok, "Plain thrown values are supported", "Captured type: " record.errorType "`nMessage: " record.errorMessage)
    }

    static TestDirectReporting() {
        this.Before("3. Direct reporting", "Write one structured JSON line through ErrorReporter.Report().")
        result := ErrorReporter.Report(Error("Intentional direct report"), "Direct reporting demonstration failed")
        line := result.ok ? this.ReadLastLine(result.path) : "No primary log line was written."
        ok := result.ok && FileExist(result.path) && InStr(line, '"message":"Direct reporting demonstration failed"')
        this.Check(ok, "A JSONL record was written", this.ResultDetail(result) "`n`nLast log line:`n" line)
    }

    static TestRedaction() {
        this.Before(
            "4. Sensitive-data redaction",
            "Temporarily place a marker on the clipboard, then report a message containing a URL, "
            "a Secrets.* reference, and that clipboard marker. The clipboard is restored immediately."
        )
        savedClipboard := ClipboardAll()
        clipboardMarker := "ERROR_DEMO_CLIPBOARD_VALUE_9F31"
        try {
            A_Clipboard := clipboardMarker
            result := ErrorReporter.Report(
                "Visit https://example.test/private and use Secrets.ApiToken with " clipboardMarker,
                "Redaction demonstration failed"
            )
            line := result.ok ? this.ReadLastLine(result.path) : ""
        } finally {
            A_Clipboard := savedClipboard
        }

        ok := result.ok
            && InStr(line, "[REDACTED_URL]")
            && InStr(line, "[REDACTED_SECRET]")
            && InStr(line, "[REDACTED_CLIPBOARD]")
            && !InStr(line, clipboardMarker)
        this.Check(ok, "Known sensitive values were redacted", "Sanitized log line:`n" line)
    }

    static TestSafeCallSuccess() {
        this.Before("5. SafeCall success", "Run a successful callable and preserve its return value.")
        result := SafeCall((*) => 20 + 22, "Addition failed")
        ok := result.status = "success" && result.value = 42 && HasProp(result, "durationMs")
        this.Check(ok, "SafeCall returned a successful result", "Status: " result.status "`nValue: " result.value "`nDuration: " result.durationMs " ms")
    }

    static TestSafeCallFailure() {
        this.Before(
            "6. SafeCall failure containment",
            "The callable will throw now. SafeCall should return execution-failed and this demo should continue."
        )
        result := SafeCall(
            (*) => this.ThrowPlainValue("Intentional plain-string SafeCall failure"),
            "The SafeCall demonstration failed"
        )
        ok := result.status = "execution-failed"
            && HasProp(result, "errorRecord")
            && result.errorRecord.message = "The SafeCall demonstration failed"
        details := "Status: " result.status
        if HasProp(result, "errorRecord")
            details .= "`nCaptured message: " result.errorRecord.errorMessage
        this.Check(ok, "The failure was contained and logged", details "`n`nThis MsgBox proves execution continued.")
    }

    static TestCallbackArgumentForwarding() {
        this.Before(
            "7. SafeCallback argument forwarding",
            "Call a protected callback with two arguments and verify that both reach the original callable."
        )
        handler := SafeCallback(
            (values*) => values[1] ":" values[2],
            "Argument forwarding failed"
        )
        result := handler.Call("left", "right")
        ok := result.status = "success" && result.value = "left:right"
        this.Check(ok, "SafeCallback preserved its arguments", "Returned value: " result.value)
    }

    static TestTimerFailure() {
        this.Before(
            "8. Real timer callback failure",
            "A one-shot SetTimer callback will throw after this MsgBox closes. SafeCallback should catch it, log it, "
            "show a TrayTip, and allow the demo to continue."
        )
        holder := {result: "pending"}
        handler := SafeCallback(
            (*) => this.ThrowIntentional("Intentional timer failure"),
            "The timer demonstration failed"
        )
        RunTimer(*) {
            holder.result := handler.Call()
        }
        SetTimer(RunTimer, -100)
        Sleep(400)
        ok := IsObject(holder.result) && holder.result.status = "execution-failed"
        status := IsObject(holder.result) && HasProp(holder.result, "status") ? holder.result.status : String(holder.result)
        this.Check(ok, "The timer error was contained", "Timer result: " status "`n`nThe main demo is still running.")
    }

    static TestGuiFailure() {
        this.Before(
            "9. Real GUI event failure",
            "A small window will open. Click 'Trigger failing GUI callback'. After the failure is caught, "
            "the same window remains usable; click 'Continue demo' to proceed."
        )
        holder := {result: "not triggered"}
        testGui := Gui("+AlwaysOnTop", "SafeCallback GUI test")
        testGui.SetFont("s10", "Segoe UI")
        statusText := testGui.AddText("w390", "No error triggered yet.")
        failButton := testGui.AddButton("xm y+14 w390 h36", "Trigger failing GUI callback")
        continueButton := testGui.AddButton("xm y+10 w390 h32", "Continue demo")
        handler := SafeCallback(
            (*) => this.ThrowIntentional("Intentional GUI event failure"),
            "The GUI demonstration failed"
        )
        HandleFailureClick(args*) {
            holder.result := handler.Call(args*)
            statusText.Text := "Caught successfully. This window still works."
        }
        CloseDemoGui(*) {
            testGui.Destroy()
        }
        failButton.OnEvent("Click", HandleFailureClick)
        continueButton.OnEvent("Click", CloseDemoGui)
        testGui.OnEvent("Close", CloseDemoGui)
        testGui.Show("AutoSize Center")
        hwnd := testGui.Hwnd
        WinWaitClose("ahk_id " hwnd)

        ok := IsObject(holder.result) && holder.result.status = "execution-failed"
        status := IsObject(holder.result) && HasProp(holder.result, "status") ? holder.result.status : String(holder.result)
        this.Check(ok, "The GUI event error was contained", "GUI callback result: " status)
    }

    static TestNotification() {
        this.Before(
            "10. Non-modal notification",
            "After this MsgBox closes, Notifier.Info() will show a TrayTip without creating an error record."
        )
        result := Notifier.Info(
            "This is an intentional error-handling demo notification.",
            "AutoHotkey demo",
            4
        )
        Sleep(750)
        this.Check(result.ok, "The notification call succeeded", "A non-modal TrayTip was requested without misclassifying it as an error.")
    }

    static TestRotation() {
        this.Before(
            "11. Log rotation",
            "Temporarily lower the size threshold for this isolated demo log, then report another record to trigger rotation."
        )
        logDir := ErrorReporter.GetLogDir()
        beforeCount := this.CountRotatedLogs(logDir)
        originalMaximum := ErrorReporter.MAX_LOG_BYTES
        try {
            ErrorReporter.MAX_LOG_BYTES := 1
            result := ErrorReporter.Report("rotation trigger", "Rotation demonstration failed")
        } finally {
            ErrorReporter.MAX_LOG_BYTES := originalMaximum
        }
        afterCount := this.CountRotatedLogs(logDir)
        ok := result.ok && afterCount > beforeCount && FileExist(logDir "\error.log.jsonl")
        this.Check(ok, "The previous log was rotated", "Rotated files before: " beforeCount "`nRotated files after: " afterCount)
    }

    static TestFallbackReporting() {
        this.Before(
            "12. Reporter fallback",
            "Temporarily point LOCALAPPDATA at an invalid path. The primary write should fail safely and append "
            "a reporter diagnostic to A_Temp instead."
        )
        activeTestRoot := EnvGet("LOCALAPPDATA")
        try {
            EnvSet("LOCALAPPDATA", "?:\invalid-error-demo-path")
            result := ErrorReporter.Report("fallback trigger", "Fallback demonstration failed")
        } finally {
            EnvSet("LOCALAPPDATA", activeTestRoot)
        }
        ok := !result.ok && HasProp(result, "fallback") && FileExist(result.fallback)
        this.Check(ok, "Primary reporting failed without crashing", this.ResultDetail(result))
    }

    static Before(title, explanation) {
        MsgBox(explanation "`n`nClick OK to run this test.", title, "Iconi")
    }

    static Check(condition, title, details := "") {
        if condition {
            this.passed += 1
            MsgBox("PASS`n`n" details, title, "Iconi")
        } else {
            this.failed += 1
            MsgBox("FAIL`n`n" details, title, "Iconx")
        }
    }

    static ThrowIntentional(message) {
        throw Error(message)
    }

    static ThrowPlainValue(message) {
        throw message
    }

    static ReadLastLine(path) {
        try text := RTrim(FileRead(path, "UTF-8"), "`r`n")
        catch
            return ""
        if text = ""
            return ""
        lines := StrSplit(text, "`n", "`r")
        return lines[lines.Length]
    }

    static CountRotatedLogs(logDir) {
        count := 0
        Loop Files, logDir "\error.log.*.jsonl", "F"
            count += 1
        return count
    }

    static ResultDetail(result) {
        details := ""
        for propertyName in ["path", "fallback", "error"] {
            if HasProp(result, propertyName)
                details .= (details = "" ? "" : "`n") propertyName ": " result.%propertyName%
        }
        return details = "" ? "No extra result details." : details
    }
}

InteractiveErrorHandlingDemo.Run()
