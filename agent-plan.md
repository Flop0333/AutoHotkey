# Agent plan: daily ticket-implementation agent

Design proposal for [#47](https://github.com/Flop0333/AutoHotkey/issues/47). This
is the taxonomy/design doc referenced by
[`.github/ISSUE_TEMPLATE/agent-task.yml`](.github/ISSUE_TEMPLATE/agent-task.yml)
and by the risk labels in [`.github/labels.yml`](.github/labels.yml) — it didn't
exist yet, so it's being created as part of this ticket.

Status: **proposal, not yet implemented.** Nothing in this doc runs until a
follow-up PR adds the actual workflow and it's reviewed.

## 1. Risk taxonomy (reference)

Matches the labels already in `.github/labels.yml`:

| Label | Meaning | Auto-agent eligible? |
|---|---|---|
| `risk: read` | No state change (docs, comments, reports). | Yes |
| `risk: reversible` | Easy-to-undo local change (code, config, a new workflow). | Yes |
| `risk: sensitive` | Private context or meaningful external impact (secrets, external services, unattended PR creation itself). | No — human-authored only |
| `risk: destructive` | Requires human execution. | No, never |

The daily agent **only** picks up issues labeled `agent-ready` AND
(`risk: read` OR `risk: reversible`). `sensitive`/`destructive` issues are
filtered out at the query level, not just by convention, so a mislabeled issue
can't slip through — see §3.

## 2. Trigger

```yaml
on:
  schedule:
    - cron: "0 8 * * *"   # 08:00 UTC daily
  workflow_dispatch: {}
concurrency:
  group: daily-ticket-agent
  cancel-in-progress: false
```

- Daily cron, plus manual dispatch for testing/on-demand runs.
- `concurrency` (no cancel-in-progress) prevents two runs overlapping and
  picking the same issue twice if a manual run and the scheduled run collide.

## 3. Issue selection

1. Query: `gh issue list --label agent-ready --label "risk: read" --state open`
   plus the same for `risk: reversible` (GitHub's label filter is AND, so this
   needs two queries, unioned).
2. Filter to `size: S` or `size: M` only — `size: L` issues are hard-excluded
   from auto-pickup (see §9); they always need a human to kick off.
3. Exclude any issue that already carries an `agent-in-progress` label (new
   label, added to `labels.yml` — see §7) so a slow-running task from
   yesterday isn't picked up again before its PR lands. **Simplification vs.
   the original proposal**: dropped the separate "exclude if already has a
   linked open PR" check — GitHub doesn't expose a simple, reliable way to
   query that (Projects/timeline APIs are either preview-only or fragile to
   parse), and `agent-in-progress` already prevents the one case that check
   was really guarding against (the daily agent re-picking its own
   in-flight work). A human opening a competing PR against the same issue
   independently is an acceptable edge case for v1 — it just means the
   agent's PR and the human's PR both reference the same issue, which a
   reviewer resolves normally.
4. Sort remaining candidates: `size: S` before `size: M`, then oldest
   `created_at` first within the same size. Small, old issues surface first —
   this keeps individual runs fast and predictable.
5. Take the first candidate. If none, log "no eligible issue" and exit 0.

Implemented in
[`.github/scripts/Select-AgentIssue.ps1`](.github/scripts/Select-AgentIssue.ps1).
Note for anyone touching this script: avoid `Sort-Object <property> -Unique`
on objects built from `ConvertFrom-Json` — it was found (by hand, while
building this) to silently drop legitimate entries when combining a
single-object JSON result with an array JSON result, which is exactly the
shape two `gh issue list` calls with different result counts produce. Dedupe
explicitly with a hashtable instead, as the script does.

This logic lives in a small script (`.github/scripts/Select-AgentIssue.ps1`,
mirroring the style of `Generate-Dashboard.ps1`) rather than inline YAML, so
it's testable and readable.

## 4. Execution / sandboxing

- Runs on a GitHub-hosted `ubuntu-latest` runner — no persistent state, fresh
  VM per run, matching `ahk-tests.yml`'s existing pattern.
- Workflow permissions scoped to the minimum needed:
  ```yaml
  permissions:
    contents: write
    pull-requests: write
    issues: write
  ```
  No `id-token`, no `pages`, no access beyond this repo.
- Immediately after selecting an issue, the workflow:
  1. Adds the `agent-in-progress` label to the issue (claims it, so a
     concurrent/next-day run skips it).
  2. Moves its Project board item to **In Progress** via
     [`.github/scripts/Set-BoardStatus.ps1`](.github/scripts/Set-BoardStatus.ps1)
     (Projects v2 GraphQL, written for this ticket and reusable by #49),
     reusing the existing `ADD_TO_PROJECT_PAT` secret and `PROJECT_URL`
     variable — no new secrets for board access. Note for anyone reusing
     this script: `gh api graphql`'s `-f query=<text>` mangles a query
     containing double quotes when the value is built up in PowerShell and
     forwarded to the native `gh.exe`; pass the query from a temp file via
     `-F query=@<path>` instead (`-F`, not `-f` — only `-F/--field` supports
     the `@file` form). Found by hand while building this.
- Checks out a new branch: `agent/issue-<number>-<slugified-title>`.
- Runs the agent (Claude Code, via `anthropics/claude-code-action` or the CLI
  directly) with the issue's title + body as the task prompt, plus a fixed
  system prompt: *"Implement only what's described. Follow the acceptance
  criteria as a checklist. Do not touch files outside the listed scope
  without a clear reason. Run any repo tests before finishing if this repo
  has them."*
- New secret required: `ANTHROPIC_API_KEY` (or whichever credential the
  chosen runner needs) — this is the one new one--time setup step, documented
  in the workflow header the same way `add-to-project.yml` documents its two.
- Timeout: `timeout-minutes: 20` on the job, so a stuck run doesn't hang the
  daily schedule indefinitely.
- After the agent finishes: run the existing test suite
  (`Tests/Invoke-SyntaxCheck.ps1`, `Invoke-UnitTests.ps1`,
  `Invoke-IntegrationTests.ps1`) locally in the job *before* pushing. If tests
  fail, the workflow does **not** open a PR — it pushes the branch anyway (for
  inspection) and comments on the issue explaining the run failed its own
  tests, removing `agent-in-progress` so it can be retried.

## 5. PR format

- Title: `<issue title>` (drop the `[Task]:` prefix).
- Body:
  ```
  Implements #<number>.

  <one-paragraph summary the agent writes of what it changed and why>

  ---
  Opened automatically by the daily ticket agent from #47.
  Closes #<number>.
  ```
- `Closes #<number>` is only included if the agent's own test run passed —
  otherwise the PR (if opened at all) uses `Relates to #<number>` so merging
  doesn't silently close an issue whose acceptance criteria aren't actually
  met.
- Labelled `agent-authored` (new label, see §7) so the PR-review agent (#48)
  and dashboard enrichment (#53) can identify it without guessing from branch
  name.
- **Never auto-merged.** A human always reviews and merges. This is the
  primary safety rail: the agent can open a PR, but nothing lands on `main`
  without a person clicking merge.

## 6. Failure modes handled

| Situation | Behavior |
|---|---|
| No eligible issue | Exit 0, no PR, no label changes. |
| Agent produces no diff | Comment on the issue explaining nothing changed, remove `agent-in-progress`, no PR. |
| Agent's own tests fail | Push branch for inspection, comment with failure summary, remove `agent-in-progress`, no `Closes` keyword. |
| Job times out | `agent-in-progress` label is left on — a human notices and manually clears it or the next run's staleness check (see below) removes labels older than 24h before selecting. |
| Issue was closed/edited mid-run | Not specifically detected in v1; the PR still opens referencing the issue number, human review catches the mismatch. Worth hardening later if it happens in practice. |

## 7. New labels

Add to `.github/labels.yml` (synced automatically by the existing
`sync-labels.yml`):

- `agent-in-progress` — an automated agent has claimed this issue and is
  working on it.
- `agent-authored` — this PR was opened by the daily ticket agent, not a
  human.

## 8. Out of scope for v1

- Auto-merging (never — always manual).
- Handling `risk: sensitive`/`risk: destructive` issues at all.
- Picking more than one issue per run.
- Retrying a failed run automatically (a human re-triggers via
  `workflow_dispatch` after fixing whatever broke).

## 9. Decisions (resolved 2026-09-07)

1. **Agent runner**: `anthropics/claude-code-action`.
2. **Schedule time**: 08:00 UTC, as proposed.
3. **`size: L` issues**: hard-excluded from auto-pickup. The selection query
   (§3) filters to `size: S` or `size: M` only — `size: L` issues are never
   eligible for unattended pickup regardless of age, and always need a human
   to kick off manually.
