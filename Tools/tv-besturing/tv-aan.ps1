# tv-aan.ps1 - zet de Philips tv aan.
# 1) Wake-on-LAN maakt het netwerk van de tv wakker (de tv blijft dan nog in standby)
# 2) Daarna zet de Philips-API de tv echt aan (eenmalig koppelen met tv-koppelen.ps1)

param(
    # netwerkkabel (eth0) en wifi (wifi0) van de tv
    [string[]]$Macs = @("1C:5A:6B:98:7C:AE", "30:52:cb:0c:7f:31"),
    [string]$Broadcast = "192.168.1.255",
    [int]$MaxWachtSeconden = 30
)

. (Join-Path $PSScriptRoot "philips-api.ps1")
$cfg = Get-TvConfig
if (-not $cfg) { throw "Nog niet gekoppeld: draai eerst tv-koppelen.ps1" }

function Send-Wol {
    $udp = New-Object System.Net.Sockets.UdpClient
    $udp.EnableBroadcast = $true
    foreach ($Mac in $Macs) {
        $bytes = ($Mac -split '[:-]') | ForEach-Object { [Convert]::ToByte($_, 16) }
        $packet = [byte[]](,0xFF * 6) + ($bytes * 16)
        foreach ($target in $Broadcast, "255.255.255.255", $TvIp) {
            foreach ($port in 7, 9) { [void]$udp.Send($packet, $packet.Length, $target, $port) }
        }
    }
    $udp.Close()
}

function Get-PowerState {
    try { return (Invoke-TvApi -Path "powerstate" -User $cfg.user -Pass $cfg.pass).powerstate }
    catch { return $null }
}

$start = Get-Date
while (((Get-Date) - $start).TotalSeconds -lt $MaxWachtSeconden) {
    $state = Get-PowerState
    if ($state -eq "On") { Write-Output "Tv staat aan."; return }
    if ($state) {
        # Netwerk is wakker, scherm nog uit: aan-opdracht sturen
        try {
            Invoke-TvApi -Path "powerstate" -Method POST -User $cfg.user -Pass $cfg.pass -Body @{ powerstate = "On" } | Out-Null
        } catch {
            Invoke-TvApi -Path "input/key" -Method POST -User $cfg.user -Pass $cfg.pass -Body @{ key = "Standby" } | Out-Null
        }
        Start-Sleep -Seconds 2
        if ((Get-PowerState) -eq "On") { Write-Output "Tv aangezet."; return }
    } else {
        Send-Wol
    }
    Start-Sleep -Seconds 1
}
Write-Output "Tv niet aan gekregen binnen $MaxWachtSeconden seconden."
exit 1
