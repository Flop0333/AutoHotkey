param([int]$TimeoutSeconds = 30)

$ErrorActionPreference = "Stop"
Import-Module (Join-Path $PSScriptRoot "Support\AhkRunner.psm1") -Force

try {
    $ahkExe = Get-AhkExecutable
} catch {
    Write-Error $_.Exception.Message
    exit 1
}

$testFile = Join-Path $PSScriptRoot "Integration\Logging.Integration.Tests.ahk"
$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("ahk-integration-tests-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $tempDir | Out-Null
$previousLogDir = $env:AUTOHOTKEY_LOG_DIR
$env:AUTOHOTKEY_LOG_DIR = Join-Path $tempDir "Logs"

try {
    $stdoutPath = Join-Path $tempDir "stdout.txt"
    $stderrPath = Join-Path $tempDir "stderr.txt"
    $run = Invoke-AhkScript -AhkExePath $ahkExe.Source -ScriptPath $testFile `
        -StdOutPath $stdoutPath -StdErrPath $stderrPath -TimeoutSeconds $TimeoutSeconds
    $stdout = if (Test-Path $stdoutPath) { Get-Content -Raw $stdoutPath } else { "" }
    Write-Host $stdout
    if (-not $run.Exited) {
        Write-Error "Logging integration test timed out after ${TimeoutSeconds}s."
        exit 1
    }
    if ($run.ExitCode -ne 0) {
        $stderr = if (Test-Path $stderrPath) { Get-Content -Raw $stderrPath } else { "" }
        Write-Error "Logging integration test failed with exit code $($run.ExitCode). $stderr"
        exit 1
    }
} finally {
    $env:AUTOHOTKEY_LOG_DIR = $previousLogDir
    Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
}

Write-Host "Logging integration test passed."
