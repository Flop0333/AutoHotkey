# philips-api.ps1 - gedeelde functies voor de Philips JointSpace API (v5, digest auth)

$script:TvIp       = "192.168.1.169"
$script:ApiBase    = "https://$($script:TvIp):1926/5"
$script:ConfigPath = Join-Path $PSScriptRoot "tv-config.json"
# TODO: Vernieuw de Philips-koppeling, bewaar de nieuwe koppelgegevens lokaal buiten Git
# en beoordeel daarna hoe de oude gegevens uit de Git-geschiedenis worden verwijderd.

# De tv gebruikt een zelfondertekend certificaat: dat accepteren we alleen voor deze sessie
if (-not ("TvTrustAll" -as [type])) {
    Add-Type @"
using System.Net; using System.Security.Cryptography.X509Certificates;
public class TvTrustAll : ICertificatePolicy {
    public bool CheckValidationResult(ServicePoint s, X509Certificate c, WebRequest r, int p) { return true; }
}
"@
}
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TvTrustAll
[System.Net.ServicePointManager]::SecurityProtocol  = 'Tls12,Tls11,Tls'
# De tv-webserver kan niet overweg met "Expect: 100-continue" en sluit dan de verbinding
[System.Net.ServicePointManager]::Expect100Continue = $false

function Invoke-TvApi {
    param(
        [string]$Path,
        [string]$Method = "GET",
        $Body = $null,
        [string]$User = $null,
        [string]$Pass = $null
    )
    $uri = "$($script:ApiBase)/$Path"
    $req = [System.Net.HttpWebRequest]::Create($uri)
    $req.Method = $Method
    $req.Timeout = 5000
    if ($User) {
        $cache = New-Object System.Net.CredentialCache
        $cache.Add([Uri]$uri, "Digest", (New-Object System.Net.NetworkCredential($User, $Pass)))
        $req.Credentials = $cache
    }
    if ($Body -ne $null) {
        $bytes = [Text.Encoding]::UTF8.GetBytes(($Body | ConvertTo-Json -Depth 5 -Compress))
        $req.ContentType = "application/json"
        $req.ContentLength = $bytes.Length
        $s = $req.GetRequestStream(); $s.Write($bytes, 0, $bytes.Length); $s.Close()
    }
    $resp = $req.GetResponse()
    $text = (New-Object System.IO.StreamReader($resp.GetResponseStream())).ReadToEnd()
    $resp.Close()
    if ($text) { return ($text | ConvertFrom-Json) }
}

function Get-TvConfig {
    if (-not (Test-Path $script:ConfigPath)) { return $null }
    return (Get-Content $script:ConfigPath -Raw | ConvertFrom-Json)
}
