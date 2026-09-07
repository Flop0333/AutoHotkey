<#
Moves an issue's Project (v2) board item to a given Status column
("Todo" / "In Progress" / "Done"). Used by daily-agent.yml, and reusable by
any future workflow that needs to move a card (e.g. #49's board/issue sync).

Requires a token with Projects read/write access in $env:GH_TOKEN - the
default GITHUB_TOKEN cannot write to Projects v2 (same limitation noted in
add-to-project.yml), so callers should pass the ADD_TO_PROJECT_PAT secret.

Silently does nothing if the issue has no matching board item, so it's safe
to call for an issue that isn't (yet) on the board.
#>
param(
    [Parameter(Mandatory)] [string]$ProjectUrl,   # e.g. https://github.com/users/Flop0333/projects/8
    [Parameter(Mandatory)] [int]$IssueNumber,
    [Parameter(Mandatory)] [ValidateSet("Todo", "In Progress", "Done")] [string]$Status
)

$ErrorActionPreference = "Stop"

if ($ProjectUrl -notmatch '^https://github\.com/(users|orgs)/([^/]+)/projects/(\d+)/?$') {
    throw "PROJECT_URL '$ProjectUrl' doesn't look like a Project (v2) URL (expected https://github.com/users|orgs/<owner>/projects/<number>)."
}
$ownerType = $Matches[1]   # "users" or "orgs"
$owner = $Matches[2]
$projectNumber = [int]$Matches[3]
$ownerField = if ($ownerType -eq "users") { "user" } else { "organization" }

function Invoke-GraphQL($query, [hashtable]$vars) {
    # Passed via a temp file, not inline -f query="...", because PowerShell's
    # argument marshalling to the native gh.exe mangles embedded double
    # quotes (e.g. `name: "Status"`), producing invalid GraphQL.
    $queryFile = New-TemporaryFile
    Set-Content -Path $queryFile -Value $query -NoNewline
    try {
        # -F (not -f) is required here: only -F/--field does the "@file reads
        # the value from a file" substitution that -f/--raw-field lacks.
        $args = @("api", "graphql", "-F", "query=@$queryFile")
        foreach ($key in $vars.Keys) {
            $isInt = $vars[$key] -is [int]
            $flag = if ($isInt) { "-F" } else { "-f" }
            $args += $flag
            $args += "$key=$($vars[$key])"
        }
        $out = gh @args
        if ($LASTEXITCODE -ne 0) { throw "gh api graphql failed: $out" }
        $out | ConvertFrom-Json
    } finally {
        Remove-Item $queryFile -ErrorAction SilentlyContinue
    }
}

$projectQuery = @"
query(`$owner: String!, `$number: Int!) {
  $ownerField(login: `$owner) {
    projectV2(number: `$number) {
      id
      field(name: "Status") {
        ... on ProjectV2SingleSelectField { id options { id name } }
      }
      items(first: 100) {
        nodes { id content { ... on Issue { number } } }
      }
    }
  }
}
"@
$result = Invoke-GraphQL $projectQuery @{ owner = $owner; number = $projectNumber }
$project = $result.data.$ownerField.projectV2
if (-not $project) { throw "Could not find project $projectNumber for $ownerType/$owner - check PROJECT_URL." }

$item = $project.items.nodes | Where-Object { $_.content.number -eq $IssueNumber } | Select-Object -First 1
if (-not $item) {
    Write-Host "Issue #$IssueNumber has no board item yet (maybe add-to-project.yml hasn't run for it) - skipping."
    exit 0
}

$option = $project.field.options | Where-Object { $_.name -eq $Status } | Select-Object -First 1
if (-not $option) { throw "Board has no '$Status' option on its Status field." }

$mutation = @"
mutation(`$project: ID!, `$item: ID!, `$field: ID!, `$option: String!) {
  updateProjectV2ItemFieldValue(input: {
    projectId: `$project, itemId: `$item, fieldId: `$field,
    value: { singleSelectOptionId: `$option }
  }) { projectV2Item { id } }
}
"@
Invoke-GraphQL $mutation @{ project = $project.id; item = $item.id; field = $project.field.id; option = $option.id } | Out-Null

Write-Host "Moved issue #$IssueNumber to '$Status' on the board."
