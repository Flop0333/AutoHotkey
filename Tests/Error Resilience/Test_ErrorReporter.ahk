; Test harness for ErrorReporter (offline, writes to temp/log folder)
#Include <Lib\Core\ErrorRecord>
#Include <Lib\Core\ErrorReporter>

Try {
    rec := ErrorRecord.FromThrown({ message: "Test exception from harness", stack: "TestStack" }, { serviceId: "test_harness", severity: "error", category: "test" })
    res := ErrorReporter.Report(rec)
    MsgBox("Report result: " (res.ok ? "OK" : "FAIL") "\n" (res.path ?? res.fallback ?? res.error))

    ; Now force rotation by writing a large record
    big := StrRepeat("X", 3 * 1024 * 1024)
    rec2 := ErrorRecord.FromThrown({ message: big }, { serviceId: "test_harness", severity: "error", category: "test-large" })
    res2 := ErrorReporter.Report(rec2)
    MsgBox("Large write result: " (res2.ok ? "OK" : "FAIL") "\n" (res2.path ?? res2.fallback ?? res2.error))
} catch {
    MsgBox("Test harness failed: " e.Message)
}
