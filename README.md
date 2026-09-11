# Welcome to my AutoHotkey productivity suite 👋

[![AHK Tests](https://github.com/Flop0333/AutoHotkey/actions/workflows/ahk-tests.yml/badge.svg)](https://github.com/Flop0333/AutoHotkey/actions/workflows/ahk-tests.yml)

This is the AutoHotkey v2 system I use to make Windows faster, more personal, and more fun. It combines global hotkeys, mouse controls, virtual desktops, OCR, speech, and modern dashboards in one modular toolkit.

It started as a collection of small scripts and grew into a profile-aware automation suite with shared libraries, structured logging, automated tests, and GitHub-powered maintenance.

## ✨ A few highlights

- 🖥️ **Virtual desktop automation** — switch desktops with CapsLock shortcuts and launch the right apps for each workspace.
- 🪟 **Fast window control** — drag, resize, close, pin, and keep windows on top from the keyboard or mouse.
- 🚀 **Age of Efficiency** — search bookmarks, launch apps, and run commands from one WebView2-powered interface.
- 🎹 **Macro Board** — a customizable Stream Deck-style dashboard for frequently used actions.
- 📸 **Screen Snipper with OCR** — capture the screen, copy or save an image, and extract text.
- 🎛️ **Control Deck** — inspect processes, logs, tests, profiles, and machine health from one control centre.
- 🔊 **Text Speaker** — read selected text or an OCR screen region aloud with Windows speech synthesis.
- 🖱️ **Mouse gestures and extra-button actions** — control common tasks without reaching for menus.
- 🧩 **Profiles and local secrets** — adapt one checkout to different computers without committing personal data.

## 🚀 The dashboards

### AutoHotkey Control Deck

The suite control centre shows what is running, flags missing startup apps, surfaces logs and environment health, runs the complete test suite, and provides safe reload, exit, restart, stop, and profile-switch actions. It starts hidden with the suite, so it opens instantly from the tray or Macro Board; Logger notifications land on Logs, and the Age of Efficiency `Test` command lands on Tests.

Its retro maintenance-console interface combines a readable system terminal with original pixel-art navigation, status modules, hardware panels, and action controls. Every readout in the status strip and on the Overview opens the section behind it.

![AutoHotkey Control Deck](Dashboards/Control%20Deck/Demo.png)

### Age of Efficiency

A keyboard-first command launcher for bookmarks, searches, applications, scripts, timers, and other utilities.

![Age of Efficiency demo](Dashboards/Age%20of%20Efficiency/Demo.gif)

### Macro Board

A customizable action grid that brings frequently used commands together in a visual, Stream Deck-style interface.

![Macro Board demo](Dashboards/Macro%20Board/Demo.gif)

## 🏗️ More than a folder of scripts

The suite brings several technologies and ideas together:

- **AutoHotkey v2** for hotkeys, Windows automation, GUIs, and reusable application wrappers.
- **WebView2 with HTML, CSS, and JavaScript** for richer dashboard interfaces backed by AutoHotkey controllers.
- **Profile-aware startup** for machine-specific apps, desktops, hotkeys, and behavior.
- **Local secrets management** that keeps personal values outside Git while maintaining a tracked catalog.
- **Structured logging and visual test results** for understanding failures quickly.
- **Explicit dependency boundaries** that keep includes predictable and activation in executable entry points.
- **PowerShell test runners and GitHub Actions** for documentation, architecture, syntax, unit, and integration checks.
- **GitHub Projects and optional scheduled agents** for issue triage, implementation, review, changelogs, and project status. Agent workflows require the [documented GitHub configuration](docs/AUTOMATION.md#required-github-configuration).

## 🛠️ Try it

1. Install [AutoHotkey v2](https://www.autohotkey.com/) on Windows.
2. Clone or download this repository.
3. Run `Startup/Startup.ahk`.

The suite is intentionally code-first: editing a clear script can be faster—and more flexible—than clicking through another settings screen.

## 📚 Explore the project

- [Project guide](docs/PROJECT-GUIDE.md) — structure, startup, development, and documentation map
- [Architecture](docs/ARCHITECTURE.md) — include direction, activation, composition, and testability
- [Installation](docs/INSTALLATION.md) — requirements, profiles, secrets, and Windows auto-start
- [Apps and scripts](docs/APPS.md) — every maintained user-facing tool and entry point
- [Testing](docs/TESTING.md) — local tests, CI, and the Control Deck Tests section
- [Automation](docs/AUTOMATION.md) — GitHub workflows, board connections, and scheduled agents
- [AI agent guide](AGENTS.md) — focused instructions for coding agents

Feel free to explore, adapt the ideas, report a bug, or share feedback. I hope something here inspires your own Windows workflow. 💭

## 🔑 License

Original project code is available under the [MIT License](LICENSE), so it may
be used, modified, and redistributed, including commercially. Bundled
third-party libraries retain their own terms; see the
[third-party notices](THIRD-PARTY-NOTICES.md) for details.
