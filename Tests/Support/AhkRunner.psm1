<#
.SYNOPSIS
    Shared helpers for running AutoHotkey v2 scripts from PowerShell with a
    timeout, used by both Invoke-SyntaxCheck.ps1 and Invoke-UnitTests.ps1.
#>

function Get-AhkExecutable {
    # AutoHotkey.exe (v2) must already be on PATH - see the setup step in
    # .github/workflows/ahk-tests.yml for how CI installs it.
    $ahkExe = Get-Command "AutoHotkey.exe" -ErrorAction SilentlyContinue
    if (-not $ahkExe) {
        $ahkExe = Get-Command "AutoHotkey64.exe" -ErrorAction SilentlyContinue
    }
    if (-not $ahkExe) {
        throw "Could not find AutoHotkey.exe or AutoHotkey64.exe on PATH."
    }
    return $ahkExe
}

function Invoke-AhkScript {
    param(
        [Parameter(Mandatory = $true)] [string]$AhkExePath,
        [Parameter(Mandatory = $true)] [string]$ScriptPath,
        [string]$StdOutPath,
        [Parameter(Mandatory = $true)] [string]$StdErrPath,
        [int]$TimeoutSeconds = 15
    )

    $startArgs = @{
        FilePath              = $AhkExePath
        ArgumentList          = @("/ErrorStdOut", "`"$ScriptPath`"")
        PassThru              = $true
        RedirectStandardError = $StdErrPath
        WindowStyle           = "Hidden"
    }
    if ($StdOutPath) {
        $startArgs.RedirectStandardOutput = $StdOutPath
    }

    $proc = Start-Process @startArgs

    # Touching .Handle forces PowerShell to open the process with the access
    # rights needed to read .ExitCode later - without this, .ExitCode silently
    # comes back empty even though the process exited normally.
    $null = $proc.Handle

    $exited = $proc.WaitForExit($TimeoutSeconds * 1000)
    if (-not $exited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        return [pscustomobject]@{ Exited = $false; ExitCode = $null }
    }

    return [pscustomobject]@{ Exited = $true; ExitCode = $proc.ExitCode }
}

Export-ModuleMember -Function Get-AhkExecutable, Invoke-AhkScript
