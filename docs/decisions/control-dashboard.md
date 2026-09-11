# AutoHotkey Control Dashboard: design record

This records the decisions used to ship the **AutoHotkey Control Dashboard**: one WebView2 cockpit for the running suite. The shipped code, `Startup/Startup.ahk`, and the focused documents are authoritative.

## Goal

Today the suite is operated from the tray menu (Reload, Profile, Log Dashboard, Test Dashboard, Exit) and from two separate WebView2 windows that each show one slice of the system. The Control Dashboard replaces that split with a single window that answers three questions and acts on them:

- **What is running?** Profile, uptime, the AutoHotkey processes that belong to the suite, and whether the expected startup set is actually up.
- **Is anything wrong?** This session's log entries by severity, the last test run, and environment health.
- **Can I change it from here?** Reload, exit, switch profile, restart a single app, run tests, and emit test notifications.

## Scope

| In scope | Out of scope |
|---|---|
| Rename `Dashboards/Log Dashboard` to `Dashboards/Control Dashboard` and keep the log views as one section. | The Logger popup (`Dashboards/Logger`), which stays the resident notification surface. |
| Absorb the Test Dashboard into a Tests section and retire the standalone dashboard once it is at parity. | Remote or network control of the suite. Everything stays local and in-process-family. |
| Add suite control: reload, exit, profile switch, per-script restart/stop. | Editing profiles, secrets, or hotkeys from the dashboard. |
| Add a health/diagnostics section. | Replacing the Macro Board or Age of Efficiency launchers. |

## Sections

1. **Overview** — profile card, secrets file state, the session's log counts by severity (with how many are unread), last test result, and the primary actions (Open in VS Code, Reload suite, Exit suite). The status strip shows the suite's processor use beside its LIVE marker, the running-script count with the session uptime, and the same log counts, whether or not they have been read. The git branch sits in the title bar beside the window controls. Until tests have run this session, the strip and the Overview offer a Run tests button in place of a test result. Each strip readout and Overview card opens the section that explains it; the Secrets card opens `Secrets/My Secrets.json` in VS Code.
2. **Processes** — the AutoHotkey processes that belong to the suite: script name, path, PID, start time. Per row: restart or stop. Processes running from outside the repository are listed last. Expected-but-missing entries are flagged so a crashed app is visible without reading the log.
3. **Logs** — the current Log Dashboard view: severity/script filters, sorting by clicking the Time, Severity, Script, or Message column header, detail panel with message and stack, copy to clipboard, archived sessions.
4. **Tests** — run all suites or one suite, live run status, the last run's per-suite pass/fail and duration, and the run history already written to `Logs/test-run-history.log`.
5. **Profiles** — every profile from `Profiles/Profile Manager.ahk`, the active one first, which device names map to it, and a switch action that restarts the suite into the chosen profile.
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

The Control Dashboard uses an original **AHK Control Deck** theme: a dark 1990s maintenance console rendered with black, brown, oxblood, copper, brass, and semantic status colours. The generated runtime artwork and its source-of-truth palette are catalogued in `Dashboards/Control Dashboard/User Interface/assets/control-deck/ASSET-MANIFEST.md`; HTML and CSS continue to own all labels, layout, focus, and responsive behavior.

- The persistent rail is a numbered module selector with a compact horizontal mode for narrow windows. The custom title bar and global status HUD remain visible from every section.
- Cards, dialogs, buttons, window controls, status symbols, and action icons use the locally bundled pixel-art kit. Nine-slice-style `border-image` treatment preserves panel and button corners as components resize.
- Logs and test output keep native text and table layouts on dark screen surfaces; decoration never becomes part of the data or blocks pointer input.
- Status is communicated through shape, label, and colour. Keyboard focus remains visible, selectable rows support Enter and Space, and nonessential motion respects `prefers-reduced-motion`.
- Motion is limited to short state changes, system messages, and active sampling indicators. There is no continuous CRT flicker or network-loaded visual dependency.
- Keyboard-first: number keys navigate between sections, `R` runs tests, `/` focuses the log filter, and `Esc` closes the detail panel.
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

## Decisions made

- The tray keeps one **Control Dashboard** item alongside Reload and Exit.
- A declarative startup list is consumed by both `RunStartup()` and the Processes section, which flags expected-but-missing scripts.
- The Tests section runs the combined `Invoke-AllTests.ps1` workflow so local and CI behaviour stay aligned.
