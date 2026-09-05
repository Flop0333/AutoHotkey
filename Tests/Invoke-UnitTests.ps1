<#
.SYNOPSIS
    Runs every AutoHotkey v2 unit test file in Tests/Unit.

.DESCRIPTION
    Each Tests/Unit/*.Tests.ahk file is a standalone AutoHotkey v2 entry point
    built on Tests/Support/Assert.ahk: it registers test cases with
    TestKit.Run(name, func), then calls TestKit.Report() once at the end to
    print PASS/FAIL lines to stdout and ExitApp() with 0 (all passed) or 1
    (at least one failed).

    This script just discovers those files, runs each one, and prints its
    stdout. A test file that never reaches TestKit.Report() - most likely
    because it has a load-time error somewhere in its #Include chain - is
    detected as a timeout, the same way Invoke-SyntaxCheck.ps1 detects one.
#>

param(
    [int]$TimeoutSeconds = 20
)

$ErrorActionPreference = "Stop"
$unitTestDir = Join-Path $PSScriptRoot "Unit"

Import-Module (Join-Path $PSScriptRoot "Support\AhkRunner.psm1") -Force

try {
    $ahkExe = Get-AhkExecutable
} catch {
    Write-Error $_.Exception.Message
    exit 1
}

$testFiles = @(Get-ChildItem -Path $unitTestDir -Filter "*.Tests.ahk" -File | Sort-Object Name)
if ($testFiles.Count -eq 0) {
    Write-Error "No *.Tests.ahk files found under $unitTestDir."
    exit 1
}

Write-Host "Found $($testFiles.Count) unit test file(s) to run.`n"

$fileResults = @()
$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("ahk-unit-tests-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $tempDir | Out-Null

try {
    foreach ($testFile in $testFiles) {
        $stdoutPath = Join-Path $tempDir ((New-Guid).Guid + ".stdout.txt")
        $stderrPath = Join-Path $tempDir ((New-Guid).Guid + ".stderr.txt")

        $run = Invoke-AhkScript -AhkExePath $ahkExe.Source -ScriptPath $testFile.FullName `
            -StdOutPath $stdoutPath -StdErrPath $stderrPath -TimeoutSeconds $TimeoutSeconds

        $stdout = ""
        if (Test-Path $stdoutPath) {
            $rawStdout = Get-Content -Raw $stdoutPath
            if ($null -ne $rawStdout) { $stdout = $rawStdout }
        }

        Write-Host "--- $($testFile.Name) ---"

        if (-not $run.Exited) {
            Write-Host $stdout
            Write-Host "TIMEOUT after ${TimeoutSeconds}s - likely a blocked load-time error dialog somewhere in this file's #Include chain."
            $fileResults += [pscustomobject]@{ File = $testFile.Name; Status = "TIMEOUT" }
            continue
        }

        Write-Host $stdout

        if ($run.ExitCode -ne 0) {
            $stderr = ""
            if (Test-Path $stderrPath) {
                $rawContent = Get-Content -Raw $stderrPath
                if ($null -ne $rawContent) { $stderr = $rawContent.Trim() }
            }
            if ($stderr) { Write-Host $stderr }
            $fileResults += [pscustomobject]@{ File = $testFile.Name; Status = "FAIL" }
            continue
        }

        $fileResults += [pscustomobject]@{ File = $testFile.Name; Status = "PASS" }
    }
} finally {
    Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
}

Write-Host "=== Summary ==="
$fileResults | Format-Table -AutoSize | Out-String | Write-Host

$failedFiles = @($fileResults | Where-Object { $_.Status -ne "PASS" })
if ($failedFiles.Count -gt 0) {
    Write-Host "$($failedFiles.Count) of $($fileResults.Count) test file(s) failed."
    exit 1
}

Write-Host "All $($fileResults.Count) test file(s) passed."
exit 0
