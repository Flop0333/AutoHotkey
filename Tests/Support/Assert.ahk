; Minimal, dependency-free assertion and reporting helpers for AHK unit tests.
;
; Each *.Tests.ahk file is a standalone AutoHotkey v2 entry point: it registers
; test cases with TestKit.Run(name, func), then calls TestKit.Report() once at
; the end to print PASS/FAIL lines to stdout and ExitApp() with 0 (all passed)
; or 1 (at least one failed).

class Assert {
    static Equal(expected, actual, message := "") {
        if expected != actual
            throw Error(Assert._Prefix(message) "Expected [" String(expected) "] but got [" String(actual) "]")
    }

    static NotEqual(notExpected, actual, message := "") {
        if notExpected = actual
            throw Error(Assert._Prefix(message) "Expected value to differ from [" String(notExpected) "]")
    }

    static True(condition, message := "Expected condition to be true") {
        if !condition
            throw Error(message)
    }

    static False(condition, message := "Expected condition to be false") {
        if condition
            throw Error(message)
    }

    static ArrayEqual(expected, actual, message := "") {
        if expected.Length != actual.Length
            throw Error(Assert._Prefix(message) "Expected array of length " expected.Length " but got " actual.Length)
        for index, value in expected
            if value != actual[index]
                throw Error(Assert._Prefix(message) "Mismatch at index " index ": expected [" String(value) "] but got [" String(actual[index]) "]")
    }

    static Throws(func, message := "Expected function to throw") {
        threw := false
        try
            func.Call()
        catch
            threw := true
        if !threw
            throw Error(message)
    }

    static DoesNotThrow(func, message := "") {
        try
            func.Call()
        catch as err
            throw Error(Assert._Prefix(message) "Expected no throw but got: " err.Message)
    }

    static Fail(message) {
        throw Error(message)
    }

    static _Prefix(message) => message ? message ". " : ""
}

class TestKit {
    static _results := []

    static Run(name, testFunc) {
        try {
            testFunc.Call()
            this._results.Push({ name: name, passed: true, error: "" })
        } catch as err {
            this._results.Push({ name: name, passed: false, error: err.Message })
        }
    }

    static Report() {
        failed := 0
        for result in this._results {
            line := (result.passed ? "PASS" : "FAIL") " - " result.name
            if !result.passed {
                line .= " :: " result.error
                failed++
            }
            FileAppend(line "`n", "*")
        }
        FileAppend("`n" this._results.Length " test(s), " failed " failed.`n", "*")
        ExitApp(failed > 0 ? 1 : 0)
    }
}
