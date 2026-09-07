<#
Nudges issues labeled needs-human-decision that have gone quiet for a while.
See .github/workflows/stale-nudges.yml and issue #51.

Uses the issue's updatedAt as the staleness clock rather than tracking
separate state: posting a nudge comment bumps updatedAt, which naturally
prevents re-nudging the same issue again until another $DaysThreshold days
of silence pass. Any other activity (a human comment, a relabel) also
resets the clock, which is the desired behavior - it means the issue isn't
stale anymore.
#>
param(
    [Parameter(Mandatory)] [string]$Repo,   # e.g. "Flop0333/AutoHotkey"
    [int]$DaysThreshold = 14
)

$ErrorActionPreference = "Stop"

$lines = gh issue list --repo $Repo --state open --label "needs-human-decision" `
    --json number,title,updatedAt --limit 100
if ($LASTEXITCODE -ne 0) { throw "gh issue list failed" }
# Must be two statements, not `@((...) | ConvertFrom-Json)`: wrapping a
# pipeline expression directly with @() does not flatten it the way
# wrapping an already-materialized array variable does - on an empty JSON
# array this produces a 1-element array containing an empty array, not a
# 0-element array. Verified by hand while building this.
$parsedIssues = ($lines -join "`n") | ConvertFrom-Json
$issues = @($parsedIssues)

if ($issues.Count -eq 0) {
    Write-Host "No open needs-human-decision issues - nothing to check."
    exit 0
}

$now = (Get-Date).ToUniversalTime()
$nudged = @()

foreach ($issue in $issues) {
    $updated = [datetime]$issue.updatedAt
    $ageDays = [math]::Floor(($now - $updated).TotalDays)

    if ($ageDays -lt $DaysThreshold) {
        Write-Host "Skipping #$($issue.number): idle $ageDays`d, under the $DaysThreshold`d threshold."
        continue
    }

    $body = "This has been labeled ``needs-human-decision`` with no activity for $ageDays days. Flagging it in case it's been missed - no other action taken."
    gh issue comment $issue.number --repo $Repo --body $body
    if ($LASTEXITCODE -ne 0) { throw "Failed to comment on #$($issue.number)" }
    Write-Host "Nudged #$($issue.number) (idle $ageDays`d): $($issue.title)"
    $nudged += $issue.number
}

if ($nudged.Count -eq 0) {
    Write-Host "Checked $($issues.Count) issue(s), none past the $DaysThreshold-day threshold."
} else {
    Write-Host "Nudged $($nudged.Count) issue(s): $($nudged -join ', ')"
}
