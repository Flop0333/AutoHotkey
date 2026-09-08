<#
Posts (or updates) a plain-English CI failure summary comment on the PR
that triggered a failed AHK Tests run, or marks a prior summary resolved
once the tests pass again. See .github/workflows/ci-failure-summary.yml
and issue #52.

Notes on how this extracts the failure, from testing against a real failed
run (id 34163396289) while building this:
- `gh run view --log-failed` labels most/all lines "UNKNOWN STEP" rather
  than the actual step name - this is a documented gh limitation
  ("due to platform constraints..."), not something this script can fix.
  So this does NOT try to slice the log by step boundaries.
- The reliable way to name the failed step is the jobs API
  (`.steps[] | select(.conclusion=="failure")`), which this uses instead.
- For the actual error text, this repo's test runners (Invoke-UnitTests.ps1
  / Invoke-IntegrationTests.ps1) print `FAIL - <test name>` lines on
  failure, which are far more useful than the generic
  `##[error]Process completed with exit code 1` PowerShell wrapper message
  - so FAIL lines are preferred when present, falling back to ##[error]
  lines, and finally to the last few lines of the log if neither appears
  (an unexpected crash shape this script wasn't specifically written for).
#>
param(
    [Parameter(Mandatory)] [string]$Repo,        # e.g. "Flop0333/AutoHotkey"
    [Parameter(Mandatory)] [long]$RunId,
    [Parameter(Mandatory)] [string]$HeadBranch,
    [Parameter(Mandatory)] [ValidateSet("success", "failure", "cancelled", "skipped", "timed_out")]
    [string]$Conclusion
)

$ErrorActionPreference = "Stop"
$Marker = "<!-- ci-failure-summary -->"

# workflow_run events' own `pull_requests` array is unreliable (a known gh
# Actions limitation - it's frequently empty even for genuine PR runs), so
# look the PR up ourselves from the head branch instead.
$prLines = gh pr list --repo $Repo --head $HeadBranch --state open --json number
$parsedPrs = ($prLines -join "`n") | ConvertFrom-Json
$prs = @($parsedPrs)
if ($prs.Count -eq 0) {
    Write-Host "No open PR for branch '$HeadBranch' - nothing to comment on (probably a push-to-main run)."
    exit 0
}
$prNumber = $prs[0].number

function Find-ExistingComment {
    # Filtered in PowerShell, not via `--jq '... contains(\"...\")'`: embedding
    # double quotes in a --jq expression hits the same PowerShell-to-native-exe
    # quote-mangling problem documented in Invoke-GitHubGraphQL.ps1, and was
    # confirmed here too while building this (jq saw a bareword and errored
    # with "function not defined").
    $lines = gh pr view $prNumber --repo $Repo --json comments
    $parsed = ($lines -join "`n") | ConvertFrom-Json
    $comment = $parsed.comments | Where-Object { $_.body -like "*$Marker*" } | Select-Object -Last 1
    if (-not $comment) { return $null }
    # `.id` here is a GraphQL node id (e.g. "IC_kwDORPu..."), not the plain
    # numeric id the REST comments endpoint below needs - that only shows up
    # as the #issuecomment-<id> fragment of `.url`. Found by hand: PATCHing
    # with the GraphQL id 404s.
    if ($comment.url -match '#issuecomment-(\d+)$') { $Matches[1] } else { $null }
}

function Set-PRComment {
    param([string]$Body, [string]$ExistingId)
    # Written via a temp file and -F body=@file (create) / a temp file with
    # gh api's -F (update), not inline -f/--body "...": log excerpts can
    # contain double quotes, which hits the same PowerShell-to-native-exe
    # quote-mangling problem documented in Invoke-GitHubGraphQL.ps1.
    $bodyFile = New-TemporaryFile
    Set-Content -Path $bodyFile -Value $Body -NoNewline
    try {
        if ($ExistingId) {
            gh api "repos/$Repo/issues/comments/$ExistingId" -X PATCH -F "body=@$bodyFile" | Out-Null
        } else {
            gh pr comment $prNumber --repo $Repo --body-file $bodyFile | Out-Null
        }
        if ($LASTEXITCODE -ne 0) { throw "Failed to post/update PR comment (exit $LASTEXITCODE)" }
    } finally {
        Remove-Item $bodyFile -ErrorAction SilentlyContinue
    }
}

if ($Conclusion -ne "failure") {
    $existingId = Find-ExistingComment
    if ($existingId) {
        $body = "$Marker`n✅ **Resolved** - AHK Tests passed on the latest push (run: https://github.com/$Repo/actions/runs/$RunId)."
        Set-PRComment -Body $body -ExistingId $existingId
        Write-Host "Marked prior failure summary as resolved (comment $existingId)."
    } else {
        Write-Host "Conclusion is '$Conclusion' and there's no prior failure summary - nothing to do."
    }
    exit 0
}

$jobsLines = gh api "repos/$Repo/actions/runs/$RunId/jobs"
$parsedJobs = ($jobsLines -join "`n") | ConvertFrom-Json
# As above: filtered in PowerShell rather than via a --jq expression with an
# embedded quoted string literal, which hits the same quote-mangling bug.
$failedSteps = @($parsedJobs.jobs.steps | Where-Object { $_.conclusion -eq "failure" } | ForEach-Object { $_.name })
$stepText = if ($failedSteps.Count -gt 0) { $failedSteps -join ", " } else { "(unknown step)" }

$rawLog = gh run view $RunId --repo $Repo --log-failed
$cleanLines = ($rawLog -split "`n") | ForEach-Object {
    # Strip gh's "job\tstep\ttimestamp " prefix and ANSI colour codes.
    $line = $_ -replace '^\S+\t[^\t]*\t\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z ?', ''
    $line -replace '\x1b\[[0-9;]*[a-zA-Z]', ''
}

$failLines = @($cleanLines | Where-Object { $_ -match '^FAIL - ' })
$errorLines = @($cleanLines | Where-Object { $_ -match '##\[error\]' })

$excerpt = if ($failLines.Count -gt 0) {
    $failLines -join "`n"
} elseif ($errorLines.Count -gt 0) {
    $errorLines -join "`n"
} else {
    ($cleanLines | Select-Object -Last 15) -join "`n"
}
if ($excerpt.Length -gt 3000) { $excerpt = $excerpt.Substring(0, 3000) + "`n... (truncated)" }

$body = @"
$Marker
**AHK Tests failed** - step: ``$stepText``

``````
$excerpt
``````

Full run: https://github.com/$Repo/actions/runs/$RunId
"@

$existingId = Find-ExistingComment
Set-PRComment -Body $body -ExistingId $existingId
if ($existingId) {
    Write-Host "Updated existing failure summary (comment $existingId) on PR #$prNumber."
} else {
    Write-Host "Posted new failure summary on PR #$prNumber."
}
