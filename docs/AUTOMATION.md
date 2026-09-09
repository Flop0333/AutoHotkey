# Startup and GitHub automation

This repository has two independent automation layers:

- **Windows startup** launches the local AutoHotkey suite. See [Installation and startup](../INSTALLATION.md) and `Startup/Startup.ahk`.
- **GitHub automation** connects the repository, issues, Project 8, pull requests, CI, GitHub Pages, and scheduled agent work.

The GitHub repository is [Flop0333/AutoHotkey](https://github.com/Flop0333/AutoHotkey). Workflow YAML and the scripts it calls are the source of truth; this page is the operational overview.

## Required GitHub configuration

Configure these under **Repository settings → Secrets and variables → Actions**:

| Name | Type | Used for |
|---|---|---|
| `PROJECT_URL` | Variable | URL of the linked GitHub Projects v2 board. The current setup uses `https://github.com/users/Flop0333/projects/8`. |
| `ADD_TO_PROJECT_PAT` | Secret | Fine-grained personal access token with Projects read/write access. GitHub's automatic token cannot update a user-owned Projects v2 board. |
| `ANTHROPIC_API_KEY` | Secret | Claude Code access for the daily implementation, idea-triage, and PR-review workflows. |
| `GITHUB_TOKEN` | Automatic | Repository-scoped token supplied by Actions for issues, pull requests, releases, workflow logs, Pages, labels, and commits. Do not create it manually. |

Keep credential values out of workflow files, logs, issues, and documentation. A missing required value should make the affected workflow fail visibly.

Repository settings must also enable GitHub Pages through Actions. The Project board is expected to have a single-select **Status** field with `Todo`, `In Progress`, and `Done` options.

## Workflow map

All cron expressions use UTC. Amsterdam local time is UTC+1 in winter and UTC+2 in summer.

| Workflow | Trigger | Connection and outcome |
|---|---|---|
| [Add issues to project](../.github/workflows/add-to-project.yml) | Issue opened | Adds every new repository issue to the configured Projects v2 board using `ADD_TO_PROJECT_PAT` and `PROJECT_URL`. |
| [AHK Tests](../.github/workflows/ahk-tests.yml) | Push or pull request targeting `main` | On `windows-latest`, downloads the latest official AutoHotkey v2 release and runs syntax, unit, and logging integration tests. Concurrent runs for the same ref cancel older ones. |
| [CI failure summary](../.github/workflows/ci-failure-summary.yml) | Completed **AHK Tests** run | For PR-originated runs, posts or updates one plain-English failure comment. When CI recovers, it marks the previous summary resolved. Uses workflow-log and PR access. |
| [Dashboard](../.github/workflows/dashboard.yml) | Push to `main`, daily 06:00, or manual | Builds a static status page from issues, recent AHK Tests runs, agent PRs, and `CHANGELOG.md`, then deploys it to GitHub Pages. |
| [Daily ticket agent](../.github/workflows/daily-agent.yml) | Daily 08:00 or manual | Selects one eligible issue, claims it, moves it to In Progress, and asks Claude Code to implement it and open a PR. Never auto-merges. |
| [Idea triage agent](../.github/workflows/idea-triage.yml) | Monday 07:00 or manual | Uses Claude Code to turn concrete `idea` issues into scoped `agent-ready` tasks, or labels unclear ideas `needs-human-decision` with an explanation. |
| [PR review agent](../.github/workflows/pr-review.yml) | PR opened or updated | Uses Claude Code to leave advisory COMMENT reviews. It never approves or requests changes, and attempts to review only the new diff after an earlier bot review. |
| [Stale decision nudges](../.github/workflows/stale-nudges.yml) | Monday 09:00 or manual | Comments on open `needs-human-decision` issues after 14 quiet days. Any issue activity resets the clock. |
| [Sync board status on reopen](../.github/workflows/sync-board-status.yml) | Issue reopened | Moves the corresponding Project item back to Todo using the Projects token. |
| [Sync labels](../.github/workflows/sync-labels.yml) | Relevant label/workflow change on `main`, or manual | Creates or updates labels from `.github/labels.yml`; `skip-delete` preserves unrelated labels. |
| [Update changelog](../.github/workflows/update-changelog.yml) | Push to `main` or manual | Adds merged PRs to `CHANGELOG.md` and commits directly to `main` as `github-actions[bot]`. A commit-message guard prevents recursion. |

## Issue and Project lifecycle

1. A new issue is automatically added to the Project in Todo.
2. An idea may be refined by the weekly triage agent or by a human.
3. Agent-ready work carries one size label and one risk label. Only size S/M plus `risk: read` or `risk: reversible` are eligible for daily unattended implementation.
4. The daily agent adds `agent-in-progress`, moves the card to In Progress, and opens an `agent-authored` PR if implementation succeeds.
5. A human reviews and merges. Nothing in this repository auto-merges a PR.
6. Native automation on the current Project closes an issue when its status becomes Done and sets status to Done when an issue closes. The repository workflow only fills the reverse gap: reopening moves it to Todo.

`risk: sensitive`, `risk: destructive`, and size L work require human control. The definitions in `.github/labels.yml` and the fields in `.github/ISSUE_TEMPLATE/agent-task.yml` are the canonical task taxonomy.

## Agent safeguards

The daily agent processes at most one issue per run. `.github/scripts/Select-AgentIssue.ps1` combines eligible risk queues, excludes size L and claimed issues, prefers size S, and then chooses the oldest task. The workflow has a 20-minute timeout and removes its claim after an ordinary failed run. A timed-out or cancelled job may leave `agent-in-progress` behind for a maintainer to clear.

The PR reviewer is advisory only. The idea-triage agent may edit issue metadata but receives no repository file-edit tools. These boundaries are encoded in the workflow permissions and Claude Code tool allowlists.

Before enabling or changing unattended behavior, run the workflow manually against a real low-risk task and inspect its issue edits, branch, PR, tests, labels, and board state.

## Supporting scripts

| Script | Responsibility |
|---|---|
| `Generate-Dashboard.ps1` | Collect GitHub data and render the Pages site into `_site`. |
| `Invoke-GitHubGraphQL.ps1` | Send Projects v2 GraphQL requests safely through the GitHub CLI. |
| `Select-AgentIssue.ps1` | Select and expose one issue for the daily agent. |
| `Send-CIFailureSummary.ps1` | Extract useful test failures and maintain one PR summary comment. |
| `Send-StaleNudges.ps1` | Find and nudge decision-blocked issues after the configured threshold. |
| `Set-BoardStatus.ps1` | Move an issue card between Todo, In Progress, and Done. |
| `Update-Changelog.ps1` | Generate changelog sections from newly merged PRs. |

The PowerShell scripts are kept outside workflow YAML so their branching, parsing, and API behavior can be read and exercised independently.

## Permissions and external services

Workflows declare the smallest practical job permissions: read-only checkout by default, issue or PR write access only for metadata operations, content write access only for implementation/changelog commits, and Pages plus OIDC permissions only for deployment.

External Actions and services currently used are:

- official `actions/checkout`, `actions/add-to-project`, `actions/upload-pages-artifact`, and `actions/deploy-pages` actions;
- `crazy-max/ghaction-github-labeler` for label synchronization;
- `anthropics/claude-code-action` for the three agent workflows;
- the official `AutoHotkey/AutoHotkey` GitHub releases API for the CI runtime.

Pin or review third-party action upgrades carefully because Actions code runs with the permissions granted to its job.

## Changing automation

- Edit the relevant file under `.github/workflows/`; keep non-trivial PowerShell in `.github/scripts/`.
- Update this document whenever triggers, schedules, credentials, permissions, board semantics, or external connections change.
- Update `.github/labels.yml` rather than managing documented taxonomy labels only through the UI.
- Use manual dispatch for a controlled validation, then inspect the Actions run and resulting GitHub state.
- Run the local suite described in [Testing](TESTING.md) when a change affects scripts used by CI.

The original daily-agent design decisions are summarized in [agent-plan.md](../agent-plan.md). Implemented workflow files always take precedence over that historical note.
