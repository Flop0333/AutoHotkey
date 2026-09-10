# Daily ticket agent: design record

This is a short historical record for [issue #47](https://github.com/Flop0333/AutoHotkey/issues/47). The proposal has been implemented. Current behavior is documented in [repository automation](../AUTOMATION.md) and defined by `.github/workflows/daily-agent.yml` plus `.github/scripts/Select-AgentIssue.ps1`.

## Decisions retained from the proposal

- Run daily at 08:00 UTC and allow manual dispatch.
- Process no more than one issue per run.
- Accept only `agent-ready` tasks with size S/M and risk read/reversible.
- Prefer size S, then the oldest issue within the same size.
- Mark selected work `agent-in-progress` and move its Project card to In Progress.
- Use Claude Code with a bounded run and repository-scoped tools.
- Open an `agent-authored` pull request for human review; never auto-merge.
- Reuse `ADD_TO_PROJECT_PAT` and `PROJECT_URL` for board access and use `ANTHROPIC_API_KEY` for Claude Code.

## Safety model

| Risk label | Meaning | Daily-agent eligible |
|---|---|---|
| `risk: read` | Read-only inspection or reporting. | Yes |
| `risk: reversible` | A scoped, easy-to-revert repository change. | Yes |
| `risk: sensitive` | Private context or meaningful external impact. | No |
| `risk: destructive` | Human execution and judgment required. | Never |

Size L tasks are also excluded from unattended selection. A human always decides whether to merge the resulting PR.

## Why this record is intentionally brief

The original proposal contained planned commands and failure behavior that changed during implementation. Keeping that text as operational documentation made it look authoritative after the workflow shipped. The live workflow, supporting scripts, labels, and automation guide now form one consistent source of truth.
