<#
Shared helper for GitHub GraphQL calls. Dot-source this file, then call
Invoke-GitHubGraphQL. Used by Set-BoardStatus.ps1 and
Close-IssueIfBoardDone.ps1 - anything that needs to talk to the Projects v2
API, which has no simple REST equivalent.
#>

function Invoke-GitHubGraphQL {
    param(
        [Parameter(Mandatory)] [string]$Query,
        [hashtable]$Variables = @{}
    )

    # Passed via a temp file, not inline -f query="...", because
    # PowerShell's argument marshalling to the native gh.exe mangles
    # embedded double quotes (e.g. `name: "Status"`), producing invalid
    # GraphQL. -F (not -f) is required: only -F/--field does the "@file
    # reads the value from a file" substitution that -f/--raw-field lacks.
    # Found by hand while building the daily ticket agent (#47).
    $queryFile = New-TemporaryFile
    Set-Content -Path $queryFile -Value $Query -NoNewline
    try {
        $ghArgs = @("api", "graphql", "-F", "query=@$queryFile")
        foreach ($key in $Variables.Keys) {
            $isInt = $Variables[$key] -is [int]
            $flag = if ($isInt) { "-F" } else { "-f" }
            $ghArgs += $flag
            $ghArgs += "$key=$($Variables[$key])"
        }
        $out = gh @ghArgs
        if ($LASTEXITCODE -ne 0) { throw "gh api graphql failed: $out" }
        $out | ConvertFrom-Json
    } finally {
        Remove-Item $queryFile -ErrorAction SilentlyContinue
    }
}
