#requires -Version 5.1
param([string]$TvOnScript, [switch]$SelfTest)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -Path (Join-Path $PSScriptRoot 'TvDisplayWake.cs') -ReferencedAssemblies 'System.dll','System.Windows.Forms.dll'

if ($SelfTest) {
    if (![TvBesturing.DisplayWake]::ShouldWake(0, 1, $true) -or
        [TvBesturing.DisplayWake]::ShouldWake(0, 1, $false) -or
        [TvBesturing.DisplayWake]::ShouldWake(-1, 1, $true) -or
        [TvBesturing.DisplayWake]::ShouldWake(1, 1, $true)) {
        throw 'Onjuiste activering van de tv.'
    }
    $test = [TvBesturing.DisplayWake]::new($null, $null)
    try {
        if ($test.ReadSessionFlags() -notin 0,1) { throw 'Windows-sessiestatus niet leesbaar.' }
    } finally { $test.Dispose() }
    'Beeldmelding en Windows-sessie gecontroleerd.'
    return
}

if ((Get-Process -Id $PID).SessionId -eq 0 -or ![IO.Path]::IsPathRooted($TvOnScript) -or
    !(Test-Path -LiteralPath $TvOnScript -PathType Leaf)) {
    throw 'Een aangemelde Windows-sessie en tv-aan.ps1 zijn vereist.'
}
$status = Join-Path $PSScriptRoot 'wake-status.txt'
$listener = [TvBesturing.DisplayWake]::new($TvOnScript, $status)
try { [Windows.Forms.Application]::Run() }
finally { $listener.Dispose() }
