# Repository guide for AI agents

This is an AutoHotkey v2 productivity suite for Windows. Keep changes scoped, preserve personal configuration, and prefer the smallest relevant validation.

## Read first

- [README.md](README.md) — visitor-facing feature showcase and documentation map.
- [docs/PROJECT-GUIDE.md](docs/PROJECT-GUIDE.md) — project structure, startup, and development overview.
- [INSTALLATION.md](docs/INSTALLATION.md) — profiles, secrets, dependencies, and local startup.
- [docs/APPS.md](docs/APPS.md) — user-facing entry points and invocation.
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — include direction, activation, composition roots, and dependency injection.
- [docs/AUTOMATION.md](docs/AUTOMATION.md) — GitHub workflows, Project board, credentials, and schedules.
- [docs/TESTING.md](docs/TESTING.md) — test architecture and commands.

## Architecture

- `Startup/Startup.ahk` owns suite initialization and is the source of truth for automatically launched apps.
- Maintained files declare their immediate dependencies. `Lib/Core.ahk` is only a compatibility facade for external or personal scripts; repository code must not include it.
- Shared code is grouped under `Lib/Core`, `Lib/Apps`, `Lib/Extensions`, `Lib/Helpers`, and `Lib/Tools`. Executable entry points own runtime activation.
- `Apps Standalone` contains independent background applications. `Apps Integrated` contains services and callable utilities used by dashboards or hotkeys.
- `Dashboards` contains WebView2 applications. Keep AHK controllers, HTML/CSS/JS interfaces, and JSON-backed state responsibilities separate.
- `Profiles` selects machine-specific behavior. `Secrets/Secrets Catalog.ahk` defines supported keys; secret values are intended to stay local.
- `.github/workflows` is the source of truth for automation. Put reusable PowerShell logic in `.github/scripts`.

## Safety and local state

Never copy contents from these git-ignored personal/runtime files into documentation or commits, and do not overwrite them unless the task explicitly requires it:

- `Secrets/My Secrets.json` and `Secrets/Removed Secrets.json`;
- `Profiles/current_profile.ini`;
- `Dashboards/Macro Board/Settings/Profile Settings/`;
- `Apps Standalone/Text Speaker/Text Speaker.settings.json`;
- `Logs/`.

Do not add real email addresses, credentials, private URLs, or secret contents to tracked files. Prefer the secrets catalog for new personal or device-specific values; only track a profile mapping when the task explicitly requires it.

`Lib/Tools/Gdip`, `Lib/Tools/OCR`, and `Lib/Tools/UIA-v2` contain bundled third-party code and examples. Avoid broad formatting or refactors there unless the task specifically targets them.

## Change rules

- Target AutoHotkey v2.
- Inspect the working tree before editing and preserve unrelated or user-owned changes.
- Preserve the CapsLock startup dependency: `Capslock Service.ahk` starts before scripts that call `CapsLock.Hotkey(...)`.
- Use analyzable relative `#Include` paths as described in `docs/ARCHITECTURE.md`. Derive runtime repository paths through `Lib/Core/Paths.ahk`; never add a fixed checkout location.
- Keep reusable behavior in shared classes/functions and entry points focused on wiring, hotkeys, and startup.
- Treat `Startup/Startup.ahk`, test discovery code, workflow YAML, and `.github/labels.yml` as authoritative over prose.
- Update the relevant focused document when changing an app entry point, default hotkey, startup set, test command, workflow trigger, credential, or external connection.
- The repository normalizes AutoHotkey, Markdown, INI, and JSON files to CRLF on checkout through `.gitattributes`.

## Working agreement

For tracked work, start from an issue with clear acceptance criteria, keep its Project status current, and use a focused branch. Open a pull request that explains the change and validation, then review the complete diff. Do not merge unless the maintainer explicitly requests it.

A change is ready for review when its acceptance criteria are met, relevant validation passes or is reported, affected documentation is updated, and the diff contains no unrelated changes, personal data, secrets, or generated files.

## Validation

From PowerShell at the repository root:

```powershell
./Tests/Invoke-DocumentationCheck.ps1
./Tests/Invoke-IncludeArchitectureCheck.ps1
./Tests/Invoke-SyntaxCheck.ps1
./Tests/Invoke-UnitTests.ps1
./Tests/Invoke-IntegrationTests.ps1
./Tests/Invoke-AllTests.ps1
```

Run the focused suite while iterating. Run all tests before finishing changes to shared code, startup, logging, includes, or test infrastructure. For documentation-only changes, check Markdown links and run `git diff --check`; run the full suite when documentation claims depend on current test discovery or startup behavior.

Do not dismiss a timeout as random: the runners use timeouts to detect AutoHotkey load-error dialogs and stuck cross-process behavior. Report what was run and any validation that could not be completed.
