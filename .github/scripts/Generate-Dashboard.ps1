<#
Builds a static status page from the GitHub API plus the repo's own
CHANGELOG.md: open agent-ready/idea issues, the last few AHK Tests CI runs,
agent PR activity, and a rendered changelog. Written to $OutDir/index.html
for actions/upload-pages-artifact. Uses GITHUB_TOKEN (read-only scope is
enough); CHANGELOG.md is read from the local checkout, not the API.
#>
param(
    [Parameter(Mandatory)] [string]$Repo,        # e.g. "Flop0333/AutoHotkey"
    [Parameter(Mandatory)] [string]$Token,
    [Parameter(Mandatory)] [string]$OutDir,
    [string]$ChangelogPath = "CHANGELOG.md"
)

$ErrorActionPreference = "Stop"
$headers = @{
    Authorization = "Bearer $Token"
    Accept        = "application/vnd.github+json"
    "User-Agent"  = "ahk-dashboard"
}

function Escape-Html($text) {
    if ($null -eq $text) { return "" }
    [System.Net.WebUtility]::HtmlEncode([string]$text)
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

# Parses this repo's own CHANGELOG.md (see Update-Changelog.ps1) - not a
# general markdown parser, just the specific `## date` / `### group` /
# `- title ([#N](url))` shape that script always produces.
function Get-ChangelogSections {
    if (-not (Test-Path $ChangelogPath)) { return @() }
    $content = Get-Content $ChangelogPath -Raw
    $content = $content -replace '(?s)^<!--.*?-->\s*', ''
    $content = $content -replace '(?m)^#\s+Changelog\s*\r?\n', ''

    $sections = @()
    foreach ($block in ([regex]::Split($content, '(?m)^## ') | Where-Object { $_.Trim() -ne "" })) {
        $lines = $block -split "`r?`n"
        $date = $lines[0].Trim()
        $groups = @()
        $currentGroup = $null
        $items = @()
        for ($i = 1; $i -lt $lines.Length; $i++) {
            $line = $lines[$i]
            if ($line -match '^###\s+(.+)') {
                if ($currentGroup) { $groups += [pscustomobject]@{ Name = $currentGroup; Items = $items } }
                $currentGroup = $Matches[1].Trim()
                $items = @()
            } elseif ($line -match '^-\s+(.+?)\s+\(\[#(\d+)\]\(([^)]+)\)\)') {
                $items += [pscustomobject]@{ Title = $Matches[1]; Number = $Matches[2]; Url = $Matches[3] }
            }
        }
        if ($currentGroup) { $groups += [pscustomobject]@{ Name = $currentGroup; Items = $items } }
        if ($date) { $sections += [pscustomobject]@{ Date = $date; Groups = $groups } }
    }
    $sections
}

$agentReady = Get-Issues "agent-ready"
$ideas = Get-Issues "idea"
$runs = Get-Runs
$agentPRs = Get-AgentPRs
$changelog = Get-ChangelogSections

function Format-IssueRows($issues) {
    if (-not $issues -or $issues.Count -eq 0) {
        return "<tr><td colspan=3 class='empty'>None open</td></tr>"
    }
    ($issues | ForEach-Object {
        $labels = (($_.labels | ForEach-Object { "<span class='tag'>$(Escape-Html $_.name)</span>" }) -join " ")
        "<tr><td><a href='$($_.html_url)'>#$($_.number) $(Escape-Html $_.title)</a></td><td>$labels</td><td>$(([datetime]$_.updated_at).ToString('yyyy-MM-dd'))</td></tr>"
    }) -join "`n"
}

function Format-RunRows($runs) {
    if (-not $runs -or $runs.Count -eq 0) {
        return "<tr><td colspan=3 class='empty'>No runs yet</td></tr>"
    }
    ($runs | ForEach-Object {
        $status = if ($_.conclusion) { $_.conclusion } else { $_.status }
        $cls = switch ($status) { "success" { "ok" }; "failure" { "fail" }; default { "pending" } }
        "<tr><td><a href='$($_.html_url)'>$(Escape-Html $_.display_title)</a></td><td><span class='pill $cls'>$status</span></td><td>$(([datetime]$_.created_at).ToString('yyyy-MM-dd HH:mm'))</td></tr>"
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
        "<tr><td><a href='$($_.html_url)'>#$($_.number) $(Escape-Html $_.title)</a></td><td><span class='pill $cls'>$status</span></td><td>$(([datetime]$_.created_at).ToString('yyyy-MM-dd'))</td></tr>"
    }) -join "`n"
}

function Format-Changelog($sections) {
    if (-not $sections -or $sections.Count -eq 0) {
        return "<p class='empty'>No changelog entries yet - CHANGELOG.md hasn't been generated (see update-changelog.yml).</p>"
    }
    $groupClass = @{ Features = "badge-feature"; Fixes = "badge-fix" }
    ($sections | ForEach-Object {
        $section = $_
        $groupsHtml = ($section.Groups | ForEach-Object {
            $group = $_
            $cls = if ($groupClass.ContainsKey($group.Name)) { $groupClass[$group.Name] } else { "badge-other" }
            $itemsHtml = ($group.Items | ForEach-Object {
                "<li><a href='$($_.Url)'>$(Escape-Html $_.Title)</a> <span class='muted'>#$($_.Number)</span></li>"
            }) -join "`n"
            "<div class='changelog-group'><span class='badge $cls'>$(Escape-Html $group.Name)</span><ul>$itemsHtml</ul></div>"
        }) -join "`n"
        "<div class='changelog-entry'><h3>$(Escape-Html $section.Date)</h3>$groupsHtml</div>"
    }) -join "`n"
}

$generated = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm 'UTC'")
$repoUrl = "https://github.com/$Repo"

$html = @"
<!doctype html>
<html lang="en"><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$(Escape-Html $Repo) - status</title>
<style>
  :root {
    color-scheme: light dark;
    --bg: #f6f7f9;
    --card: #ffffff;
    --border: #e3e6ea;
    --text: #1c2128;
    --muted: #656d76;
    --accent: #0969da;
    --ok-bg: #dafbe1; --ok-fg: #1a7f37;
    --fail-bg: #ffebe9; --fail-fg: #cf222e;
    --pending-bg: #fff8c5; --pending-fg: #9a6700;
    --tag-bg: #eef1f4; --tag-fg: #40474f;
    --shadow: 0 1px 2px rgba(16, 24, 40, .05), 0 1px 3px rgba(16, 24, 40, .04);
  }
  @media (prefers-color-scheme: dark) {
    :root {
      --bg: #0d1117;
      --card: #161b22;
      --border: #30363d;
      --text: #e6edf3;
      --muted: #8b949e;
      --accent: #4493f8;
      --ok-bg: #0f2f1c; --ok-fg: #3fb950;
      --fail-bg: #3b1219; --fail-fg: #f85149;
      --pending-bg: #3b2f07; --pending-fg: #e3b341;
      --tag-bg: #21262d; --tag-fg: #c9d1d9;
      --shadow: 0 1px 2px rgba(0, 0, 0, .3);
    }
  }
  * { box-sizing: border-box; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    max-width: 980px; margin: 0 auto; padding: 2.5rem 1.25rem 4rem;
    color: var(--text); background: var(--bg); line-height: 1.5;
  }
  header { margin-bottom: 2rem; }
  header h1 { font-size: 1.6rem; margin: 0 0 .25rem; }
  header p { margin: 0; color: var(--muted); font-size: .9rem; }
  header a { color: inherit; }
  nav { display: flex; flex-wrap: wrap; gap: .5rem 1rem; margin-top: 1rem; }
  nav a { font-size: .85rem; color: var(--accent); text-decoration: none; }
  nav a:hover { text-decoration: underline; }

  section { background: var(--card); border: 1px solid var(--border); border-radius: 12px;
    padding: 1.25rem 1.5rem 1.5rem; margin-bottom: 1.25rem; box-shadow: var(--shadow); }
  section h2 { font-size: 1.05rem; margin: 0 0 .9rem; display: flex; align-items: center; gap: .5rem; }

  table { width: 100%; border-collapse: collapse; }
  td, th { text-align: left; padding: .5rem .4rem; font-size: .88rem; }
  th { color: var(--muted); font-weight: 600; font-size: .78rem; text-transform: uppercase; letter-spacing: .03em;
    border-bottom: 1px solid var(--border); }
  tbody tr:not(:last-child) td { border-bottom: 1px solid var(--border); }
  tbody tr:hover td { background: color-mix(in srgb, var(--accent) 5%, transparent); }

  a { color: var(--accent); text-decoration: none; }
  a:hover { text-decoration: underline; }

  .pill { display: inline-block; padding: .15rem .55rem; border-radius: 999px; font-size: .78rem; font-weight: 600; }
  .pill.ok, .badge-feature { background: var(--ok-bg); color: var(--ok-fg); }
  .pill.fail, .badge-fix { background: var(--fail-bg); color: var(--fail-fg); }
  .pill.pending, .badge-other { background: var(--pending-bg); color: var(--pending-fg); }

  .tag { display: inline-block; background: var(--tag-bg); color: var(--tag-fg); border-radius: 6px;
    padding: .1rem .45rem; font-size: .76rem; margin: .1rem .2rem .1rem 0; }
  .muted { color: var(--muted); font-size: .82rem; }
  .empty { color: var(--muted); font-style: italic; font-size: .88rem; }

  .stats-row { display: flex; gap: 1rem; flex-wrap: wrap; margin-bottom: 1.25rem; }
  .stat { flex: 1 1 140px; background: var(--card); border: 1px solid var(--border); border-radius: 12px;
    padding: 1rem 1.1rem; box-shadow: var(--shadow); }
  .stat .n { font-size: 1.6rem; font-weight: 700; line-height: 1.1; }
  .stat .l { color: var(--muted); font-size: .8rem; margin-top: .2rem; }

  .changelog-entry { padding: .75rem 0; }
  .changelog-entry:not(:last-child) { border-bottom: 1px solid var(--border); }
  .changelog-entry h3 { font-size: .95rem; margin: 0 0 .5rem; color: var(--muted); font-weight: 600; }
  .changelog-group { margin: 0 0 .6rem; }
  .changelog-group .badge { display: inline-block; padding: .1rem .5rem; border-radius: 999px; font-size: .74rem;
    font-weight: 700; text-transform: uppercase; letter-spacing: .02em; margin-bottom: .3rem; }
  .changelog-group ul { margin: .3rem 0 0; padding-left: 1.2rem; }
  .changelog-group li { font-size: .88rem; margin-bottom: .15rem; }

  footer { margin-top: 2.5rem; font-size: .8rem; color: var(--muted); text-align: center; }
</style></head>
<body>
<header>
  <h1>$(Escape-Html $Repo)</h1>
  <p>Live status, generated $generated - <a href="$repoUrl">view repo</a></p>
  <nav>
    <a href="#ci">CI runs</a>
    <a href="#agent-ready">Agent-ready</a>
    <a href="#ideas">Ideas</a>
    <a href="#agent-prs">Agent PR activity</a>
    <a href="#changelog">Changelog</a>
  </nav>
</header>

<div class="stats-row">
  <div class="stat"><div class="n">$($agentReady.Count)</div><div class="l">Agent-ready issues</div></div>
  <div class="stat"><div class="n">$($ideas.Count)</div><div class="l">Ideas in backlog</div></div>
  <div class="stat"><div class="n">$($agentPRs.Count)</div><div class="l">Agent PRs (all-time)</div></div>
</div>

<section id="ci">
<h2>Recent CI runs</h2>
<table><thead><tr><th>Run</th><th>Result</th><th>When</th></tr></thead><tbody>
$(Format-RunRows $runs)
</tbody></table>
</section>

<section id="agent-ready">
<h2>Agent-ready tasks</h2>
<table><thead><tr><th>Issue</th><th>Labels</th><th>Updated</th></tr></thead><tbody>
$(Format-IssueRows $agentReady)
</tbody></table>
</section>

<section id="ideas">
<h2>Idea backlog</h2>
<table><thead><tr><th>Issue</th><th>Labels</th><th>Updated</th></tr></thead><tbody>
$(Format-IssueRows $ideas)
</tbody></table>
</section>

<section id="agent-prs">
<h2>Agent PR activity</h2>
<table><thead><tr><th>Total</th><th>Merged</th><th>Closed without merging</th><th>Avg. time to merge</th></tr></thead><tbody>
$(Format-AgentPRStats $agentPRs)
</tbody></table>
<table style="margin-top:.75rem"><thead><tr><th>PR</th><th>Outcome</th><th>Opened</th></tr></thead><tbody>
$(Format-AgentPRRows $agentPRs)
</tbody></table>
</section>

<section id="changelog">
<h2>Changelog</h2>
$(Format-Changelog $changelog)
</section>

<footer>Generated $generated by .github/workflows/dashboard.yml</footer>
</body></html>
"@

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
Set-Content -Path (Join-Path $OutDir "index.html") -Value $html -Encoding utf8
