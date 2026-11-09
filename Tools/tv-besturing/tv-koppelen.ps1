# tv-koppelen.ps1 - koppel deze laptop eenmalig aan de Philips tv.
# De tv moet AAN staan: er verschijnt een pincode op het scherm.

. (Join-Path $PSScriptRoot "philips-api.ps1")

# Publiek bekende sleutel die de Philips-app gebruikt om de pincode te ondertekenen
$secret = [Convert]::FromBase64String("JCqdN5AcnAHgJYseUn7ER5k3qgtemfUvMRghQpTfTZq7Cvv8EPQPqfz6dDxPQPSu4gKFPWkJGw32zyASgJkHwCjU")

$deviceId = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 16 | ForEach-Object { [char]$_ })
$device = @{
    device_name = "laptop"
    device_os   = "Windows"
    app_name    = "TV-aan script"
    type        = "native"
    app_id      = "app.id"
    id          = $deviceId
}

$req = Invoke-TvApi -Path "pair/request" -Method POST -Body @{
    scope  = @("read", "write", "control")
    device = $device
}
if ($req.error_id -ne "SUCCESS") { throw "Koppelverzoek mislukt: $($req | ConvertTo-Json -Compress)" }

$pin = Read-Host "Typ de pincode die op de tv staat (je hebt $($req.timeout) seconden)"

$hmac = New-Object System.Security.Cryptography.HMACSHA1 (, $secret)
$hash = $hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes("$($req.timestamp)$pin"))
$hex  = -join ($hash | ForEach-Object { $_.ToString("x2") })
$signature = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($hex))

$grant = Invoke-TvApi -Path "pair/grant" -Method POST -User $deviceId -Pass $req.auth_key -Body @{
    auth   = @{ auth_AppId = "1"; pin = $pin; auth_timestamp = $req.timestamp; auth_signature = $signature }
    device = $device
}

@{ user = $deviceId; pass = $req.auth_key } | ConvertTo-Json | Set-Content -Path $ConfigPath -Encoding UTF8
Write-Output "Gekoppeld! Gegevens opgeslagen in $ConfigPath"
