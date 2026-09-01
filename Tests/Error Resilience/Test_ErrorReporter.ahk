; Test harness for ErrorReporter (offline, writes to temp/log folder)
#Include ..\..\Lib\Core\ErrorRecord.ahk
#Include ..\..\Lib\Core\ErrorReporter.ahk

Try {
    rec := ErrorRecord.FromThrown({ message: "Test exception from harness", stack: "TestStack" }, { serviceId: "test_harness", severity: "error", category: "test" })
    res := ErrorReporter.Report(rec)
    MsgBox("Report result: " (res.ok ? "OK" : "FAIL") "`n" ResultDetail(res))

    ; Now force rotation by writing a large record
    big := ""
    Loop 3 * 1024
        big .= Format("{:1024}", "X")
    rec2 := ErrorRecord.FromThrown({ message: big }, { serviceId: "test_harness", severity: "error", category: "test-large" })
    res2 := ErrorReporter.Report(rec2)
    MsgBox("Large write result: " (res2.ok ? "OK" : "FAIL") "`n" ResultDetail(res2))
} catch as e {
    MsgBox("Test harness failed: " e.Message)
}

ResultDetail(result) {
    for propertyName in ["path", "fallback", "error"]
        if HasProp(result, propertyName)
            return result.%propertyName%
    return "No details"
}
