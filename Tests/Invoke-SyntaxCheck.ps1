<#
.SYNOPSIS
    Load-time syntax check for every AutoHotkey v2 entry-point script in the repo.

.DESCRIPTION
    AutoHotkey parses a script's entire source (including everything pulled in via
    #Include) before executing a single line of it. This script exploits that: for
    each entry point it generates a tiny wrapper that calls ExitApp() as the very
    first statement, then #Includes the real script. If the real script parses
    cleanly, the wrapper exits immediately with code 0 and none of the target's
    actual side effects (hotkeys, GUIs, Run() calls, etc.) ever execute. If the
    target has a load-time error, AutoHotkey shows a blocking error dialog instead
    of exiting, which this script detects as a timeout.

    Entry points are discovered from Startup/Startup.ahk's RunStartup() function,
    which is the single source of truth for what actually launches on this machine.
#>

param(
    [int]$TimeoutSeconds = 15
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot

# AutoHotkey.exe (v2) must already be on PATH - see the setup step in
# .github/workflows/ahk-syntax-check.yml for how CI installs it.
$ahkExe = Get-Command "AutoHotkey.exe" -ErrorAction SilentlyContinue
if (-not $ahkExe) {
    $ahkExe = Get-Command "AutoHotkey64.exe" -ErrorAction SilentlyContinue
}
if (-not $ahkExe) {
    Write-Error "Could not find AutoHotkey.exe or AutoHotkey64.exe on PATH."
    exit 1
}

# Mirrors the static properties in Lib/Core/Paths.ahk.
$pathsMap = @{
    appsIntegrated = "Apps Integrated"
    appsStandalone = "Apps Standalone"
    dashboards     = "Dashboards"
}

$startupFile = Join-Path $repoRoot "Startup\Startup.ahk"
$startupContent = Get-Content -Raw $startupFile

$targets = [System.Collections.Generic.List[string]]::new()
$targets.Add($startupFile)

$runCalls = [regex]::Matches($startupContent, 'Run\(Paths\.(\w+)\s*"([^"]+)"\)')
foreach ($m in $runCalls) {
    $pathsKey = $m.Groups[1].Value
    $relativePath = $m.Groups[2].Value
    if (-not $pathsMap.ContainsKey($pathsKey)) {
        Write-Warning "Unknown Paths.$pathsKey referenced in Startup.ahk - add it to `$pathsMap in this script."
        continue
    }
    $fullPath = Join-Path (Join-Path $repoRoot $pathsMap[$pathsKey]) $relativePath.TrimStart('\')
    $targets.Add($fullPath)
}

Write-Host "Found $($targets.Count) entry-point script(s) to check.`n"

$results = @()
$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("ahk-syntax-check-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $tempDir | Out-Null

try {
    foreach ($target in $targets) {
        $name = $target
        if ($target.StartsWith($repoRoot)) {
            $name = $target.Substring($repoRoot.Length).TrimStart('\', '/')
        }

        if (-not (Test-Path $target)) {
            $results += [pscustomobject]@{ Script = $name; Status = "MISSING"; Detail = "File not found" }
            continue
        }

        $wrapperPath = Join-Path $tempDir ((New-Guid).Guid + ".ahk")
        @"
#Requires AutoHotkey v2
ExitApp(0)
#Include $target
"@ | Set-Content -Path $wrapperPath -Encoding UTF8

        $stderrPath = Join-Path $tempDir ((New-Guid).Guid + ".stderr.txt")
        $proc = Start-Process -FilePath $ahkExe.Source -ArgumentList "/ErrorStdOut", "`"$wrapperPath`"" `
            -PassThru -RedirectStandardError $stderrPath -WindowStyle Hidden

        # Touching .Handle forces PowerShell to open the process with the access
        # rights needed to read .ExitCode later - without this, .ExitCode silently
        # comes back empty even though the process exited normally.
        $null = $proc.Handle

        $exited = $proc.WaitForExit($TimeoutSeconds * 1000)

        if (-not $exited) {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
            $results += [pscustomobject]@{ Script = $name; Status = "FAIL"; Detail = "Timed out after ${TimeoutSeconds}s - likely a blocked load-time error dialog" }
            continue
        }

        if ($proc.ExitCode -ne 0) {
            $stderr = ""
            if (Test-Path $stderrPath) {
                $rawContent = Get-Content -Raw $stderrPath
                if ($null -ne $rawContent) { $stderr = $rawContent.Trim() }
            }
            $results += [pscustomobject]@{ Script = $name; Status = "FAIL"; Detail = "Exit code $($proc.ExitCode). $stderr" }
            continue
        }

        $results += [pscustomobject]@{ Script = $name; Status = "PASS"; Detail = "" }
    }
} finally {
    Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
}

$results | Format-Table -AutoSize | Out-String | Write-Host

$failures = @($results | Where-Object { $_.Status -ne "PASS" })
if ($failures.Count -gt 0) {
    Write-Host "`n$($failures.Count) of $($results.Count) script(s) failed the syntax check."
    exit 1
}

Write-Host "`nAll $($results.Count) script(s) passed the syntax check."
exit 0
