<#
Generates a new CHANGELOG.md section from PRs merged since the last run.
See .github/workflows/update-changelog.yml and issue #54.

Idempotency: tracked via a `<!-- last-pr: N -->` marker at the top of
CHANGELOG.md, not by re-scanning what's already listed there. On the very
first run (no marker / no file yet), this processes the entire merged-PR
history, which is expected - documented in the ticket as acceptable v1
behavior rather than something to special-case away.

Only writes CHANGELOG.md - does not commit or push. The workflow handles
git add/commit/push, since that's a workflow-level concern (committer
identity, no-op detection via `git diff --cached`) rather than something
this script needs to know about.
#>
param(
    [Parameter(Mandatory)] [string]$Repo,   # e.g. "Flop0333/AutoHotkey"
    [string]$ChangelogPath = "CHANGELOG.md"
)

$ErrorActionPreference = "Stop"
$MarkerPrefix = "<!-- last-pr: "

$lastPr = 0
$existingBody = ""
if (Test-Path $ChangelogPath) {
    $content = Get-Content $ChangelogPath -Raw
    if ($content -match [regex]::Escape($MarkerPrefix) + '(\d+)\s*-->') {
        $lastPr = [int]$Matches[1]
    }
    # Body is everything after the marker line, so re-inserting it below
    # doesn't duplicate the old marker.
    $existingBody = $content -replace ('(?s)^.*?' + [regex]::Escape($MarkerPrefix) + '\d+\s*-->\s*\r?\n?'), ''
}

$lines = gh pr list --repo $Repo --state merged --json number,title,mergedAt,labels,url --limit 200
$parsed = ($lines -join "`n") | ConvertFrom-Json
$allMerged = @($parsed)
$newPrs = @($allMerged | Where-Object { $_.number -gt $lastPr } | Sort-Object number)

if ($newPrs.Count -eq 0) {
    Write-Host "No merged PRs newer than #$lastPr - nothing to add."
    exit 0
}

function Get-Group($pr) {
    $labelNames = $pr.labels | ForEach-Object { $_.name }
    if ($labelNames -contains "bug") { return "Fixes" }
    if ($labelNames -contains "enhancement") { return "Features" }
    return "Other"
}

$grouped = @{ Fixes = @(); Features = @(); Other = @() }
foreach ($pr in $newPrs) {
    $grouped[(Get-Group $pr)] += $pr
}

$today = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd")
$sectionLines = @("## $today")
foreach ($group in "Features", "Fixes", "Other") {
    if ($grouped[$group].Count -eq 0) { continue }
    $sectionLines += ""
    $sectionLines += "### $group"
    foreach ($pr in $grouped[$group]) {
        $sectionLines += "- $($pr.title) ([#$($pr.number)]($($pr.url)))"
    }
}
$newSection = ($sectionLines -join "`n") + "`n"

$newLastPr = ($newPrs | Measure-Object -Property number -Maximum).Maximum
$header = "$MarkerPrefix$newLastPr -->`n# Changelog`n`n"

$final = $header + $newSection + "`n" + ($existingBody -replace '^# Changelog\r?\n+', '')
Set-Content -Path $ChangelogPath -Value $final -Encoding utf8 -NoNewline
Write-Host "Added $($newPrs.Count) PR(s) (up to #$newLastPr) to $ChangelogPath."
