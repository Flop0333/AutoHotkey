; Test harness for ErrorReporter (offline, writes to temp/log folder)
#Include ..\..\Lib\Core\ErrorRecord.ahk
#Include ..\..\Lib\Core\ErrorReporter.ahk

Try {
    res := ErrorReporter.Report({ message: "Test exception from harness", stack: "TestStack" }, "Test report failed")
    MsgBox("Report result: " (res.ok ? "OK" : "FAIL") "`n" ResultDetail(res))

    ; Now force rotation by writing a large record
    big := ""
    Loop 3 * 1024
        big .= Format("{:1024}", "X")
    res2 := ErrorReporter.Report({ message: big }, "Large test report failed")
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
