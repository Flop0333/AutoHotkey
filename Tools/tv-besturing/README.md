# Philips tv aan/uit vanaf de laptop

PowerShell-scripts om de Philips tv ("mijn-tv", JointSpace API v5) via het netwerk aan en uit te zetten.

## Bestanden

| Bestand | Wat het doet |
|---|---|
| `tv-aan.ps1` | Zet de tv aan: Wake-on-LAN maakt het netwerk wakker, daarna stuurt de Philips-API "aan". Duurt ca. 20 sec vanuit diepe standby. |
| `tv-uit.ps1` | Zet de tv in standby. |
| `tv-koppelen.ps1` | Eenmalig koppelen met de tv (pincode op het scherm). Maakt `tv-config.json`. |
| `philips-api.ps1` | Gedeelde functies + **IP-adres van de tv** (`$script:TvIp`). |
| `tv-config.json` | Inloggegevens van de koppeling. **Privé houden**: hiermee kan iedereen op je netwerk de tv bedienen. |

## Gebruik

```powershell
powershell -ExecutionPolicy Bypass -File "pad\naar\tv-aan.ps1"
powershell -ExecutionPolicy Bypass -File "pad\naar\tv-uit.ps1"
```

`tv-aan.ps1` geeft exitcode 0 als het gelukt is en 1 als de tv binnen 30 sec niet aanging
(langer wachten: `-MaxWachtSeconden 60`).

## Vereisten

- Tv via **netwerkkabel** verbonden (via wifi werd hij niet wakker uit standby).
- Op de tv: *Instellingen > Draadloos en netwerken > Bekabeld of Wi-Fi* > **Bekabeld**, en Wake-on-LAN aan.
- Laptop in hetzelfde netwerk (192.168.1.x).

## Als het niet meer werkt

- **Ander IP-adres?** De tv had 192.168.1.169. Pas `$script:TvIp` aan in `philips-api.ps1`,
  of stel in je modem een vast IP (DHCP-reservering) in voor MAC `1C:5A:6B:98:7C:AE`.
- **403 Forbidden?** De koppeling is vervallen (bv. na fabrieksreset): draai `tv-koppelen.ps1` opnieuw
  met de tv aan, en typ de pincode binnen 60 seconden.
