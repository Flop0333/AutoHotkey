<#
Builds a static status page from the GitHub API: open agent-ready/idea issues
and the last few AHK Tests CI runs. Written to $OutDir/index.html for
actions/upload-pages-artifact. Uses GITHUB_TOKEN (read-only scope is enough).
#>
param(
    [Parameter(Mandatory)] [string]$Repo,        # e.g. "Flop0333/AutoHotkey"
    [Parameter(Mandatory)] [string]$Token,
    [Parameter(Mandatory)] [string]$OutDir
)

$ErrorActionPreference = "Stop"
$headers = @{
    Authorization = "Bearer $Token"
    Accept        = "application/vnd.github+json"
    "User-Agent"  = "ahk-dashboard"
}

function Get-Issues($label) {
    $uri = "https://api.github.com/repos/$Repo/issues?state=open&labels=$label&per_page=20"
    Invoke-RestMethod -Uri $uri -Headers $headers
}

function Get-Runs {
    $uri = "https://api.github.com/repos/$Repo/actions/workflows/ahk-tests.yml/runs?per_page=5"
    (Invoke-RestMethod -Uri $uri -Headers $headers).workflow_runs
}

function Get-AgentPRs {
    # The /pulls list endpoint (unlike /issues) has no `labels` query param,
    # but its response objects do carry a `labels` array plus `merged_at` -
    # which /issues doesn't expose for PRs - so fetch recent closed PRs and
    # filter for the agent-authored label client-side.
    $uri = "https://api.github.com/repos/$Repo/pulls?state=closed&per_page=100"
    $prs = Invoke-RestMethod -Uri $uri -Headers $headers
    @($prs | Where-Object { $_.labels.name -contains "agent-authored" })
}

$agentReady = Get-Issues "agent-ready"
$ideas = Get-Issues "idea"
$runs = Get-Runs
$agentPRs = Get-AgentPRs

function Format-IssueRows($issues) {
    if (-not $issues -or $issues.Count -eq 0) {
        return "<tr><td colspan=3 class='empty'>None open</td></tr>"
    }
    ($issues | ForEach-Object {
        $labels = ($_.labels | ForEach-Object { $_.name }) -join ", "
        "<tr><td><a href='$($_.html_url)'>#$($_.number) $($_.title)</a></td><td>$labels</td><td>$(([datetime]$_.updated_at).ToString('yyyy-MM-dd'))</td></tr>"
    }) -join "`n"
}

function Format-RunRows($runs) {
    if (-not $runs -or $runs.Count -eq 0) {
        return "<tr><td colspan=3 class='empty'>No runs yet</td></tr>"
    }
    ($runs | ForEach-Object {
        $status = if ($_.conclusion) { $_.conclusion } else { $_.status }
        $cls = switch ($status) { "success" { "ok" }; "failure" { "fail" }; default { "pending" } }
        "<tr><td><a href='$($_.html_url)'>$($_.display_title)</a></td><td class='$cls'>$status</td><td>$(([datetime]$_.created_at).ToString('yyyy-MM-dd HH:mm'))</td></tr>"
    }) -join "`n"
}

function Format-AgentPRStats($prs) {
    if (-not $prs -or $prs.Count -eq 0) {
        return "<tr><td colspan=4 class='empty'>No agent-authored PRs yet</td></tr>"
    }
    $merged = @($prs | Where-Object { $_.merged_at })
    $closedNoMerge = $prs.Count - $merged.Count
    $avgText = if ($merged.Count -gt 0) {
        $totalHours = ($merged | ForEach-Object { ([datetime]$_.merged_at - [datetime]$_.created_at).TotalHours } | Measure-Object -Sum).Sum
        "$([math]::Round($totalHours / $merged.Count, 1))h"
    } else {
        "n/a"
    }
    "<tr><td>$($prs.Count)</td><td>$($merged.Count)</td><td>$closedNoMerge</td><td>$avgText</td></tr>"
}

function Format-AgentPRRows($prs) {
    if (-not $prs -or $prs.Count -eq 0) {
        return "<tr><td colspan=3 class='empty'>None yet</td></tr>"
    }
    ($prs | Sort-Object created_at -Descending | Select-Object -First 10 | ForEach-Object {
        $status = if ($_.merged_at) { "merged" } else { "closed" }
        $cls = if ($_.merged_at) { "ok" } else { "fail" }
        "<tr><td><a href='$($_.html_url)'>#$($_.number) $($_.title)</a></td><td class='$cls'>$status</td><td>$(([datetime]$_.created_at).ToString('yyyy-MM-dd'))</td></tr>"
    }) -join "`n"
}

$generated = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm 'UTC'")

$html = @"
<!doctype html>
<html lang="en"><head>
<meta charset="utf-8"><title>AutoHotkey repo status</title>
<style>
  body { font-family: system-ui, sans-serif; max-width: 900px; margin: 2rem auto; padding: 0 1rem; color: #1a1a1a; background: #fafafa; }
  h1 { font-size: 1.4rem; } h2 { font-size: 1.1rem; margin-top: 2rem; border-bottom: 1px solid #ddd; padding-bottom: .3rem; }
  table { width: 100%; border-collapse: collapse; margin-top: .5rem; }
  td, th { text-align: left; padding: .4rem .5rem; border-bottom: 1px solid #eee; font-size: .9rem; }
  a { color: #0969da; text-decoration: none; } a:hover { text-decoration: underline; }
  .ok { color: #1a7f37; font-weight: 600; } .fail { color: #cf222e; font-weight: 600; } .pending { color: #9a6700; font-weight: 600; }
  .empty { color: #666; font-style: italic; }
  footer { margin-top: 2rem; font-size: .8rem; color: #666; }
</style></head>
<body>
<h1>AutoHotkey repo status</h1>

<h2>Recent CI runs</h2>
<table><tr><th>Run</th><th>Result</th><th>When</th></tr>
$(Format-RunRows $runs)
</table>

<h2>Agent-ready tasks</h2>
<table><tr><th>Issue</th><th>Labels</th><th>Updated</th></tr>
$(Format-IssueRows $agentReady)
</table>

<h2>Idea backlog</h2>
<table><tr><th>Issue</th><th>Labels</th><th>Updated</th></tr>
$(Format-IssueRows $ideas)
</table>

<h2>Agent PR activity</h2>
<table><tr><th>Total</th><th>Merged</th><th>Closed without merging</th><th>Avg. time to merge</th></tr>
$(Format-AgentPRStats $agentPRs)
</table>
<table><tr><th>PR</th><th>Outcome</th><th>Opened</th></tr>
$(Format-AgentPRRows $agentPRs)
</table>

<footer>Generated $generated by .github/workflows/dashboard.yml</footer>
</body></html>
"@

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
Set-Content -Path (Join-Path $OutDir "index.html") -Value $html -Encoding utf8
