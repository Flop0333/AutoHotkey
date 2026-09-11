# AutoHotkey Control Deck: design record

This is a short historical record for [epic #108](https://github.com/Flop0333/AutoHotkey/issues/108) and the retro redesign that followed it. The Control Deck has shipped: one WebView2 window that replaced the separate Log and Test Dashboards and operates the running suite. Current behavior is documented in the [app catalog](../APPS.md), [installation guide](../INSTALLATION.md), and [testing guide](../TESTING.md), and defined by the code under [`Dashboards/Control Deck`](../../Dashboards/Control%20Deck/Dashboard.ahk) and [`Apps Integrated/Suite Control`](../../Apps%20Integrated/Suite%20Control/Suite%20Control.ahk).

## Decisions retained

- **One window, six sections.** Overview, Processes, Logs, Tests, Profiles, and Health share one host. The Logger popup stays the resident notification surface and opens the Control Deck on Logs.
- **Three roles, kept apart.** `Dashboard.ahk` is the host process and composition root, `Controller.ahk` holds only the WebView callbacks, and `Control Deck.ahk` is the client API (`ShowControlDeck()`, `HideControlDeck()`) other scripts include. The page lives under `User Interface/`, with `AhkDataService.js` as its only route to the host.
- **Suite control is a service, not controller code.** Reload, exit, inventory, restart, and stop live in `Apps Integrated/Suite Control`, so the tray, a hotkey, or a unit test can call them too. Inventory reads each script's path from its hidden main window title.
- **One declarative startup list.** `SuiteStartupScripts()` drives both `RunStartup()` and the Processes section, which flags an expected script that is not running.
- **Started hidden with the suite.** The host is the last entry in that list and loads hidden, so opening it is instant; it is still started on demand when it is missing. While hidden, the page is told so and its one-second poll pauses.
- **Profile switching survives the restart.** A requested profile is recorded for the next start and honoured once, so switching to a profile that does not match the computer name is not undone by auto-detection.
- **Tests run the CI workflow.** The Tests section and the Run tests buttons start `Tests/Invoke-AllTests.ps1`, one run at a time, and read its status and history files scoped to the current suite session.
- **Session-scoped status.** Log counts, unread counts, and test results describe the current suite session; earlier sessions stay in `Logs/Archive`.

## Safety model

- The web layer can only call named callbacks. No path, command line, or script text crosses the bridge; scripts are addressed by process id and files by the host.
- Reload, exit, stop, and profile switching are confirmed in the page before anything happens, never through a message box the hidden host would open behind its own window.
- Exiting or reloading the suite ends the Control Deck too, and the confirmation says so.
- Secrets are reported as counts only. Values and key names never reach the page; the Secrets cards on the Overview and Health open the local file in VS Code rather than displaying it.
- Everything is local: files, processes, and the git status of the checkout. External commands run hidden.

## Visual direction

The **Control Deck** theme is an original, offline pixel-art kit in the style of a 1990s maintenance console, catalogued in its [asset manifest](../../Dashboards/Control%20Deck/User%20Interface/assets/control-deck/ASSET-MANIFEST.md). HTML and CSS own every label, layout, focus state, and responsive behavior; artwork is decoration only. Status is shown by shape, label, and colour together, keyboard focus stays visible, and motion respects `prefers-reduced-motion`.

## Why this record is intentionally brief

The original proposal described phases, planned files, and validation steps that changed during implementation. Keeping that text made it look authoritative after the Control Deck shipped. The code, startup list, and focused documents are now the single source of truth.
