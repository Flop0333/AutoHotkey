#requires -Version 5.1
$ErrorActionPreference = 'Stop'

$taskName = 'Tv-besturing - Beeld bij Windows-vergrendeling'
$marker = 'Tv-besturing display wake v1'
$account = [Security.Principal.WindowsIdentity]::GetCurrent()
$existing = Get-ScheduledTask -TaskPath '\' -TaskName $taskName -ErrorAction SilentlyContinue
if ($existing -and ($existing.Description -ne $marker -or
        $existing.Principal.UserId -notin @($account.Name, $account.User.Value, $env:USERNAME))) {
    throw 'Er bestaat een andere taak met deze naam.'
}
if ((Get-Process -Id $PID).SessionId -eq 0) { throw 'Voer dit uit vanuit je aangemelde Windows-account.' }

$target = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'TvBesturing'
$tvOn = Join-Path $PSScriptRoot 'tv-aan.ps1'
if (!(Test-Path -LiteralPath $tvOn -PathType Leaf) -or
    !(Test-Path -LiteralPath (Join-Path $PSScriptRoot 'tv-config.json') -PathType Leaf)) {
    throw 'Koppel de Philips-tv eerst met tv-koppelen.ps1.'
}
$runtime = Join-Path ([Environment]::SystemDirectory) 'WindowsPowerShell\v1.0\powershell.exe'
$source = Join-Path $PSScriptRoot 'tv-schermwekken.ps1'
& $runtime -NoLogo -NoProfile -NonInteractive -STA -ExecutionPolicy RemoteSigned -File $source -SelfTest
if ($LASTEXITCODE -ne 0) { throw 'De controle van de Windows-beeldmelding is mislukt.' }

New-Item -ItemType Directory -Path $target -Force | Out-Null
if ($existing.State -in @('Running', 'Queued')) { Stop-ScheduledTask -InputObject $existing }
foreach ($name in 'tv-schermwekken.ps1', 'TvDisplayWake.cs') {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination (Join-Path $target $name) -Force
}

$watcher = Join-Path $target 'tv-schermwekken.ps1'
$arguments = '-NoLogo -NoProfile -NonInteractive -STA -WindowStyle Hidden -ExecutionPolicy RemoteSigned -File "' +
    $watcher + '" -TvOnScript "' + $tvOn + '"'
$action = New-ScheduledTaskAction -Execute $runtime -Argument $arguments -WorkingDirectory $target
$logon = New-ScheduledTaskTrigger -AtLogOn -User $account.Name
$recovery = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 1)
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit ([timespan]::Zero)
$principal = New-ScheduledTaskPrincipal -UserId $account.Name -LogonType Interactive -RunLevel Limited
$definition = New-ScheduledTask -Action $action -Trigger @($logon, $recovery) -Settings $settings -Principal $principal -Description $marker
Register-ScheduledTask -TaskName $taskName -TaskPath '\' -InputObject $definition -Force | Out-Null

$started = [datetime]::Now
Start-ScheduledTask -TaskName $taskName -TaskPath '\'
$status = Join-Path $target 'wake-status.txt'
$deadline = $started.AddSeconds(25)
do {
    Start-Sleep -Seconds 1
    $task = Get-ScheduledTask -TaskName $taskName -TaskPath '\'
    $record = Get-Item -LiteralPath $status -ErrorAction SilentlyContinue
} until (($task.State -eq 'Running' -and $record.LastWriteTime -ge $started) -or [datetime]::Now -ge $deadline)
if ($task.State -ne 'Running' -or !$record -or $record.LastWriteTime -lt $started) {
    throw 'De taak kon zich niet aanmelden voor Windows-beeldmeldingen.'
}
'De tv-wekdienst draait in je Windows-sessie.'
