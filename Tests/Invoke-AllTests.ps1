<#
.SYNOPSIS
    Runs the syntax check, unit tests, and integration tests in one pass and
    logs a structured result for the Test Dashboard to display.

.DESCRIPTION
    Each suite script (Invoke-SyntaxCheck.ps1, Invoke-UnitTests.ps1,
    Invoke-IntegrationTests.ps1) calls `exit` directly, so each one is launched
    as its own child process rather than dot-sourced or called in-process.

    Writes Logs\test-run-status.json (current run state, polled by the Test
    Dashboard while a run is in progress) and appends one JSON line per run to
    Logs\test-run-history.log (newest run last, same line-delimited-JSON
    convention as Logs\errors.log). Both files live under Logs\, which is
    already git-ignored.
#>

param(
    [int]$TimeoutSeconds = 180
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$logsDir = Join-Path $repoRoot "Logs"
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir | Out-Null
}

$statusPath = Join-Path $logsDir "test-run-status.json"
$historyPath = Join-Path $logsDir "test-run-history.log"

function Write-Status {
    param([string]$Status, [hashtable]$Extra = @{})
    $obj = @{ status = $Status; updatedAt = (Get-Date).ToString("o") }
    foreach ($key in $Extra.Keys) { $obj[$key] = $Extra[$key] }
    ($obj | ConvertTo-Json -Compress) | Set-Content -Path $statusPath -Encoding UTF8
}

Write-Status "running"

$suites = @(
    @{ name = "Syntax Check"; script = Join-Path $PSScriptRoot "Invoke-SyntaxCheck.ps1" }
    @{ name = "Unit Tests"; script = Join-Path $PSScriptRoot "Invoke-UnitTests.ps1" }
    @{ name = "Integration Tests"; script = Join-Path $PSScriptRoot "Invoke-IntegrationTests.ps1" }
)

$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("ahk-all-tests-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $tempDir | Out-Null

$results = @()
try {
    foreach ($suite in $suites) {
        $stdoutPath = Join-Path $tempDir ((New-Guid).Guid + ".stdout.txt")
        $stderrPath = Join-Path $tempDir ((New-Guid).Guid + ".stderr.txt")

        $proc = Start-Process -FilePath "powershell.exe" `
            -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$($suite.script)`"") `
            -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath `
            -WindowStyle Hidden -PassThru

        # Touching .Handle forces PowerShell to open the process with the access
        # rights needed to read .ExitCode later (same fix as Tests/Support/AhkRunner.psm1).
        $null = $proc.Handle
        $exited = $proc.WaitForExit($TimeoutSeconds * 1000)

        if (-not $exited) {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
            $results += @{ name = $suite.name; status = "TIMEOUT"; exitCode = $null; output = "Timed out after ${TimeoutSeconds}s." }
            continue
        }

        $stdout = if (Test-Path $stdoutPath) { (Get-Content -Raw $stdoutPath) } else { "" }
        $stderr = if (Test-Path $stderrPath) { (Get-Content -Raw $stderrPath) } else { "" }
        $output = ("$stdout`n$stderr").Trim()

        $status = if ($proc.ExitCode -eq 0) { "PASS" } else { "FAIL" }
        $results += @{ name = $suite.name; status = $status; exitCode = $proc.ExitCode; output = $output }
    }
} finally {
    Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
}

$overall = if (@($results | Where-Object { $_.status -ne "PASS" }).Count -gt 0) { "FAIL" } else { "PASS" }
$run = @{
    timestamp     = (Get-Date).ToString("o")
    overallStatus = $overall
    suites        = $results
}

($run | ConvertTo-Json -Depth 5 -Compress) | Add-Content -Path $historyPath -Encoding UTF8
Write-Status "idle" @{ lastRunAt = $run.timestamp; lastRunStatus = $overall }

if ($overall -eq "PASS") {
    Write-Host "All test suites passed."
    exit 0
} else {
    Write-Host "One or more test suites failed."
    exit 1
}
