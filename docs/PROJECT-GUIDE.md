# AutoHotkey productivity suite guide

A personal, modular automation suite built for AutoHotkey v2 on Windows. It combines global hotkeys, window and desktop management, small productivity tools, and WebView2 dashboards. Profiles adapt the same checkout to different computers, while local secrets keep personal values out of Git.

Return to the [project welcome page](../README.md) for the feature showcase.

## Quick start

1. Install [AutoHotkey v2](https://www.autohotkey.com/).
2. Clone this repository on Windows.
3. Run `Startup/Startup.ahk`.
4. Confirm the detected profile in the tray menu and customize it if needed.

See the [installation guide](../INSTALLATION.md) for prerequisites, local configuration, and Windows auto-start.

## What is included

- **Standalone apps** provide independent tools such as the CapsLock modifier, virtual desktop manager, emoji picker, screen snipper, text speaker, mouse gestures, and window manager.
- **Integrated apps** provide shared hotkeys and utilities such as Command Storer, spell checking, timers, picture-in-picture, and mouse controls.
- **Dashboards** provide WebView2 interfaces for launching commands, running macros, viewing logs, and monitoring tests.
- **Lib** contains shared application wrappers, helpers, extensions, and third-party tools.
- **Startup, Profiles, and Secrets** coordinate machine-specific configuration and launch the enabled suite.
- **Tests** contains syntax checks, unit tests, integration tests, and a visual Test Dashboard.
- **.github** connects issues, the Project board, pull requests, CI, GitHub Pages, labels, changelog generation, and scheduled agents.

The complete inventory is in the [app and script catalog](APPS.md).

## How the suite starts

`Startup/Startup.ahk` is the source of truth for the local auto-run set. It starts the logging UI hosts, synchronizes secrets, selects the active profile, starts the CapsLock service before its consumers, and then launches the configured apps and dashboards. Optional scripts remain available without starting automatically.

GitHub automation is separate from Windows startup. Its workflows run tests, manage Project-board state, maintain repository metadata and pages, and assist with issue and pull-request work. See [repository automation](AUTOMATION.md).

## Development

Run the complete local check from PowerShell:

```powershell
./Tests/Invoke-AllTests.ps1
```

Individual syntax, unit, and integration runners are also available. See [testing](TESTING.md) for commands, discovery rules, result files, and instructions for adding tests.

AI coding agents should begin with [AGENTS.md](../AGENTS.md), which summarizes the architecture, safety boundaries, sources of truth, and validation expectations.

## Documentation

| Document | Purpose |
|---|---|
| [Welcome](../README.md) | Feature showcase and entry point for new visitors |
| [Installation](../INSTALLATION.md) | Prerequisites, profiles, secrets, startup, and troubleshooting |
| [Apps and scripts](APPS.md) | Catalog of runnable tools, dashboards, and supporting areas |
| [Automation](AUTOMATION.md) | Windows auto-run and all GitHub connections and workflows |
| [Testing](TESTING.md) | Local test suites, dashboard, CI, and test authoring |
| [Agent guide](../AGENTS.md) | Fast repository orientation for AI agents and contributors |
| [Road map](../ROAD%20MAP.md) | Future ideas and resources under consideration |

This project favors code-first configuration and small, composable AutoHotkey scripts.
