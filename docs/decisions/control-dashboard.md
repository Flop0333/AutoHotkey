# AutoHotkey Control Dashboard: design record

This is a forward-looking design record for reworking the Log Dashboard into an **AutoHotkey Control Dashboard**: one WebView2 cockpit for the running suite. Nothing here is implemented yet. Implementation is tracked by the tickets linked from the Control Dashboard epic on [Project 8](https://github.com/users/Flop0333/projects/8); the shipped code, `Startup/Startup.ahk`, and the focused documents remain authoritative once work lands.

## Goal

Today the suite is operated from the tray menu (Reload, Profile, Log Dashboard, Test Dashboard, Exit) and from two separate WebView2 windows that each show one slice of the system. The Control Dashboard replaces that split with a single window that answers three questions and acts on them:

- **What is running?** Profile, uptime, the AutoHotkey processes that belong to the suite, and whether the expected startup set is actually up.
- **Is anything wrong?** Unread log entries by severity, the last test run, and environment health.
- **Can I change it from here?** Reload, exit, switch profile, restart a single app, run tests, and emit test notifications.

## Scope

| In scope | Out of scope |
|---|---|
| Rename `Dashboards/Log Dashboard` to `Dashboards/Control Dashboard` and keep the log views as one section. | The Logger popup (`Dashboards/Logger`), which stays the resident notification surface. |
| Absorb the Test Dashboard into a Tests section and retire the standalone dashboard once it is at parity. | Remote or network control of the suite. Everything stays local and in-process-family. |
| Add suite control: reload, exit, profile switch, per-script restart/stop. | Editing profiles, secrets, or hotkeys from the dashboard. |
| Add a health/diagnostics section. | Replacing the Macro Board or Age of Efficiency launchers. |

## Sections

1. **Overview** — profile card, suite uptime, running-script count, unread log counts by severity, last test result, git branch/ahead/behind, and the primary actions (Reload suite, Exit suite, Run all tests, Send test notification / warning / error).
2. **Processes** — the AutoHotkey processes that belong to the suite: script name, path, PID, start time. Per row: restart or stop. Expected-but-missing entries are flagged so a crashed app is visible without reading the log.
3. **Logs** — the current Log Dashboard view: severity/script filters, time sort, detail panel with message and stack, copy to clipboard, archived sessions.
4. **Tests** — run all suites or one suite, live run status, the last run's per-suite pass/fail and duration, and the run history already written to `Logs/test-run-history.log`.
5. **Profiles** — every profile from `Profiles/Profile Manager.ahk`, which one is active, which device names map to it, and a switch action that restarts the suite into the chosen profile.
6. **Health** — AutoHotkey version and path, WebView2 runtime presence, resolved `Paths` roots, log session id and directory, secrets file sync state, and shortcuts to open the `Logs` folder or the repository.

## Architecture

The dashboard keeps the established dashboard shape: `Dashboard.ahk` is the composition root and host process, `Controller.ahk` holds the `WebViewToo` subclass and its `AddCallbackToScript` surface, `Control Dashboard.ahk` exposes `ShowControlDashboard()` / `HideControlDashboard()` to other scripts, and `User Interface/` holds HTML, CSS, JS, and `AhkDataService.js`.

Suite control does **not** live in the controller. A reusable service under `Apps Integrated/Suite Control/` owns it, so the same operations are callable from the tray menu, a hotkey, or a unit test:

```text
Dashboards/Control Dashboard/Dashboard.ahk   (host process, composition root)
    -> Controller.ahk                        (WebView callbacks only)
        -> Apps Integrated/Suite Control/... (reload, exit, inventory, restart)
        -> Lib/Core/OnError.ahk              (log reading and test entries)
        -> Profiles/Profile Manager.ahk      (profile list and requested profile)
```

The dashboard runs in its own process, so control actions are cross-process by nature. That is how the suite reload works: it kills every other AutoHotkey process, starts `Startup/Startup.ahk`, and exits itself. The service formalizes the rest:

- **Inventory** — enumerate AutoHotkey processes and read each one's script path from its (hidden) main window title, rather than guessing from the startup list.
- **Restart one script** — stop the process owning a script path and run it again, without touching the rest of the suite.
- **Expected set** — compare the inventory against the apps `RunStartup()` launches. A shared, declarative startup list is preferred over parsing `Startup.ahk`; that list stays authoritative for what starts.

### Profile switching across a restart

`ProfileManager.Set()` persists to `Profiles/current_profile.ini`, but a plain restart runs `RunStartup()` with no argument, which calls `SetByComputerName()` and overwrites the choice. A dashboard-initiated switch therefore needs an explicit handoff — a requested-profile value that `RunStartup()` honours once and then clears — so "switch to Work and restart" survives the restart on a machine whose computer name maps elsewhere. This is the one change outside the dashboard folder that the feature genuinely requires.

### Callback surface

Read paths stay synchronous and cheap enough to poll (`ahk.sync.*`, one second, matching the existing dashboards). Every action that changes state is a separate, explicitly named callback — no generic "run this command" bridge from the web layer.

## Safety model

- Reload, exit, and stopping a process are confirmed in the page before the callback fires; the dashboard never inherits the tray's `MsgBox` prompts into a hidden window.
- Exiting the suite from the dashboard exits the dashboard too. The page says so before it happens.
- The web layer can only call named callbacks. No arbitrary path, command line, or PowerShell string crosses the bridge.
- Test notifications write ordinary log entries through the existing `LogAndNotify*` functions, so they exercise the real path.
- Local files, local processes, no network calls beyond the git status the dashboard already reads.

## Visual direction

The current dashboards are functional but plain. The Control Dashboard is the one window that stays open, so it gets a real design pass:

- A persistent left rail for section navigation, the custom title bar the other dashboards use, and a status strip (profile, uptime, unread severities, last test result) that is visible from every section.
- One small design-token layer — background, surface, border, text, muted, accent, and one colour per severity — shared by every section instead of per-view colour literals.
- Cards for state, pills for status, one table style for logs and processes, and toasts for action results.
- Motion limited to state changes worth noticing: a run starting, a process disappearing, a new error arriving.
- Keyboard-first: number keys or arrow navigation between sections, `R` to run tests, `/` to focus the log filter, `Esc` to close the detail panel.
- The window is resized freely, so layouts are fluid rather than fixed to one screen size.

## Delivery plan

Each phase is independently mergeable and leaves the suite working.

1. **Foundations** — the Suite Control service and the requested-profile handoff, with unit coverage. No UI change yet.
2. **Rename and shell** — `Log Dashboard` becomes `Control Dashboard` across code, tray, Macro Board, Age of Efficiency, the syntax-check target list, integration tests, and documentation; the new shell renders the Logs section as it exists today.
3. **Control sections** — Overview, Processes, and Profiles on top of phase 1.
4. **Tests section** — the Test Dashboard's behaviour inside the new window, reusing `Logs/test-run-status.json` and `Logs/test-run-history.log`; the standalone dashboard is retired once it is at parity.
5. **Health and polish** — diagnostics section, keyboard shortcuts, motion, and the README showcase update.

## Validation

Beyond the usual suites, the change touches startup, includes, and logging, so `./Tests/Invoke-AllTests.ps1` applies to every phase. Additional expectations:

- Unit coverage for the inventory parsing and the requested-profile handoff, with no real process control in unit tests.
- The logging integration test keeps covering the renamed dashboard host, including its lazy start.
- `Invoke-SyntaxCheck.ps1` targets the renamed host, and the Test Dashboard target is removed only in the phase that retires it.

## Open questions

- Should the tray menu keep separate items after the rename, or collapse to a single **Control Dashboard** entry plus Reload and Exit?
- Should the expected startup set become a declarative list consumed by both `RunStartup()` and the dashboard, or should the dashboard simply report what is running?
- Should per-suite test runs be offered from the dashboard, or only the combined run that CI and the current dashboard use?
