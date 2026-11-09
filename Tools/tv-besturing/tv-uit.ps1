# tv-uit.ps1 - zet de Philips tv in standby via de Philips-API.

. (Join-Path $PSScriptRoot "philips-api.ps1")
$cfg = Get-TvConfig
if (-not $cfg) { throw "Nog niet gekoppeld: draai eerst tv-koppelen.ps1" }

Invoke-TvApi -Path "powerstate" -Method POST -User $cfg.user -Pass $cfg.pass -Body @{ powerstate = "Standby" } | Out-Null
Write-Output "Tv in standby gezet."
