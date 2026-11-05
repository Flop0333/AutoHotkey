param(
    [Parameter(Mandatory)][string]$AppPath,
    [Parameter(Mandatory)][string]$Name,
    [string]$EnvFile = ''
)

function Run-Checked([string]$Command, [string[]]$Arguments) {
    Get-Command $Command -ErrorAction Stop | Out-Null
    $output = (& $Command @Arguments 2>&1 | Out-String).Trim()
    if ($output) { Write-Host $output }
    if ($LASTEXITCODE -ne 0) { throw "$Command $($Arguments -join ' ') failed:`n$output" }
    return $output
}

function Notify([string]$Message) {
    Add-Type -AssemblyName System.Windows.Forms
    [void][System.Windows.Forms.MessageBox]::Show($Message, "Update $Name")
}

try {
    Set-Location -LiteralPath $AppPath -ErrorAction Stop
    $composeArgs = @('compose')
    if ($EnvFile) {
        if (-not (Test-Path -LiteralPath $EnvFile -PathType Leaf)) { throw "Compose env-bestand ontbreekt: $EnvFile" }
        $composeArgs += @('--env-file', $EnvFile)
    }
    $changes = (& git status --short 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) { throw "git status --short mislukt:`n$changes" }
    if ($changes) { Write-Host "Lokale wijzigingen blijven behouden:`n$changes" }
    $branch = Run-Checked git @('branch', '--show-current')
    if ($branch -ne 'main') { throw "Huidige branch is '$branch'; schakel eerst naar main." }

    Run-Checked git @('pull', '--ff-only', 'origin', 'main') | Out-Null

    Run-Checked docker ($composeArgs + @('up', '-d', '--build', '--force-recreate')) | Out-Null
    $psOutput = Run-Checked docker ($composeArgs + @('ps'))
    $expectedText = Run-Checked docker ($composeArgs + @('config', '--services'))
    $runningText = Run-Checked docker ($composeArgs + @('ps', '--status', 'running', '--services'))
    $expected = @($expectedText -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    $running = @($runningText -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    if (-not $expected.Count -or @($expected | Where-Object { $_ -notin $running }).Count) {
        throw "Niet alle Compose-services draaien. Verwacht: $($expected -join ', '); actief: $($running -join ', '). docker compose ps:`n$psOutput"
    }
    Notify "$Name is bijgewerkt en opnieuw gestart"
    exit 0
} catch {
    $message = $_.Exception.Message
    Write-Host "UPDATE MISLUKT: $message" -ForegroundColor Red
    Notify "Update van $Name mislukt:`n$message"
    Read-Host 'PowerShell blijft open. Druk op Enter om dit venster te sluiten' | Out-Null
    exit 1
}
