# Contributing

Welcome! Bug reports, practical improvements, documentation fixes, and reusable automation ideas are all appreciated. Keep changes focused and easy to understand.

## Workflow

1. Start from an issue with a clear goal and acceptance criteria. Create one first when the change needs discussion or tracking.
2. Add tracked work to the Project board. Move it from **Todo** to **In Progress** when implementation begins.
3. Check the working tree, preserve unrelated changes, and create a focused branch from the intended base.
4. Implement only the agreed scope. Prefer existing patterns and shared utilities over parallel implementations.
5. Run the relevant tests and update affected documentation.
6. Open a pull request that explains what changed, why, and how it was validated.
7. Review the full diff for accuracy, unnecessary duplication, missing information, secrets, and generated files.
8. Merge only after review. Close the issue and move it to **Done** when the work is accepted; repository automation may perform these final status updates.

Use `Closes #<issue>` in a pull request only when the implementation and required validation are complete. Use `Relates to #<issue>` and explain what remains when the work is partial or unverified.

## Change rules

- Target AutoHotkey v2 and follow the architecture and safety rules in [AGENTS.md](AGENTS.md).
- Never commit personal profiles, secret values, local settings, logs, or machine-specific paths.
- Keep entry points focused on startup and wiring; place reusable behavior in shared classes or functions.
- Treat code and workflow files as authoritative. Update prose when behavior changes instead of documenting intended behavior as if it already exists.
- Avoid unrelated formatting, vendored-library changes, and broad refactors.

## Validation

Run the smallest relevant command while iterating. For changes to shared code, startup, includes, logging, or test infrastructure, run the complete suite:

```powershell
./Tests/Invoke-AllTests.ps1
```

Documentation-only changes should at minimum have working local links and pass `git diff --check`. See [docs/TESTING.md](docs/TESTING.md) for the individual suites and test-authoring guidance.

## Definition of done

A change is ready for review when:

- the issue scope and acceptance criteria are satisfied;
- relevant tests pass, or limitations are clearly reported;
- affected documentation is accurate and concise;
- the diff contains no unrelated edits, personal data, credentials, or generated runtime files;
- the pull request links the issue and explains validation; and
- the complete diff has received a deliberate self-review.

AI tools should also read their repository instruction file: [AGENTS.md](AGENTS.md) for Codex and compatible agents, [CLAUDE.md](CLAUDE.md) for Claude Code, or [.github/copilot-instructions.md](.github/copilot-instructions.md) for GitHub Copilot.
