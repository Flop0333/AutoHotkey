<#
Picks one issue for the daily ticket agent (.github/workflows/daily-agent.yml)
to implement. See agent-plan.md section 3 for the selection rules this
implements. Read-only - makes no changes to issues or the board.

Outputs (via $env:GITHUB_OUTPUT): issue_number, issue_title, branch_prefix.
When no eligible issue exists, issue_number is left empty and the caller
should treat that as "nothing to do".
#>
param(
    [Parameter(Mandatory)] [string]$Repo   # e.g. "Flop0333/AutoHotkey"
)

$ErrorActionPreference = "Stop"

function Get-CandidateIssues($riskLabel) {
    $lines = gh issue list --repo $Repo --state open `
        --label "agent-ready" --label $riskLabel `
        --json number,title,createdAt,labels --limit 100
    if ($LASTEXITCODE -ne 0) { throw "gh issue list failed for label '$riskLabel'" }
    # PowerShell captures native stdout as a string array (one element per
    # line); ConvertFrom-Json needs it rejoined into one string first, or
    # pretty-printed/multi-line JSON parses into garbage silently.
    ($lines -join "`n") | ConvertFrom-Json
}

$combined = @(Get-CandidateIssues "risk: read") + @(Get-CandidateIssues "risk: reversible")
# An issue should only ever carry one risk label, so this union shouldn't
# have overlaps - but dedupe defensively by number. Deliberately not
# `Sort-Object number -Unique`: it drops legitimate entries on this data
# shape (single-object vs. array results from ConvertFrom-Json), verified
# by hand while testing this script.
$seenNumbers = @{}
$candidates = foreach ($c in $combined) {
    if (-not $seenNumbers.ContainsKey($c.number)) {
        $seenNumbers[$c.number] = $true
        $c
    }
}

$eligible = $candidates | Where-Object {
    $labelNames = $_.labels | ForEach-Object { $_.name }
    $size = $labelNames | Where-Object { $_ -in @("size: S", "size: M") }
    $inProgress = $labelNames -contains "agent-in-progress"
    # size: L is never auto-picked (agent-plan.md #9); agent-in-progress means
    # a previous run already claimed it and hasn't failed/finished.
    $size -and -not $inProgress
}

# Smallest first (S before M), then oldest first within the same size.
$sizeRank = @{ "size: S" = 0; "size: M" = 1 }
$picked = $eligible | Sort-Object `
    @{ Expression = { $sizeRank[($_.labels | ForEach-Object { $_.name } | Where-Object { $_ -in @("size: S", "size: M") } | Select-Object -First 1)] } }, `
    @{ Expression = { [datetime]$_.createdAt } } `
    | Select-Object -First 1

if (-not $picked) {
    Write-Host "No eligible agent-ready issue found (size S/M, risk read/reversible, not already in progress)."
    Add-Content -Path $env:GITHUB_OUTPUT -Value "issue_number="
    exit 0
}

# A stable, predictable prefix for the branch the agent will create - not
# the full branch name (the agent/action picks the rest). Also used to find
# the resulting PR afterwards.
$branchPrefix = "agent/issue-$($picked.number)-"

Write-Host "Selected #$($picked.number): $($picked.title)"
Add-Content -Path $env:GITHUB_OUTPUT -Value "issue_number=$($picked.number)"
Add-Content -Path $env:GITHUB_OUTPUT -Value "issue_title=$($picked.title)"
Add-Content -Path $env:GITHUB_OUTPUT -Value "branch_prefix=$branchPrefix"
