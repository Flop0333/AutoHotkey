# Apps and scripts

This catalog covers the maintained, user-facing entry points. “Auto-start” means launched directly by `Startup/Startup.ahk` or loaded by one of those processes. Files described as support modules are not intended to be launched alone.

Hotkeys reflect the current defaults. Profile conditions and active-window rules can narrow when they work.

## Standalone apps

| App | Starts | Use | Notes and configuration |
|---|---|---|---|
| [CapsLock Service](../Apps%20Standalone/Capslock%20Service.ahk) | Auto, first | Hold CapsLock as the suite modifier; double-tap to toggle Caps Lock normally. | Must start before desktop and window hotkeys. VM-aware behavior is in the script. |
| [Desktops Manager](../Apps%20Standalone/Desktops%20Manager/Desktops%20Manager.ahk) | Auto | `CapsLock+configured key` switches desktops; `CapsLock+Tab` returns; `CapsLock+P` pins a window. | Edit `GetDesktopsForProfile()` to define each profile's apps and layouts. Uses `VirtualDesktopAccessor.dll`; `Desktop.ahk` is its model. |
| [Emoji Sender](../Apps%20Standalone/Emoji%20Sender/Emoji%20Sender.ahk) | Auto | `Alt+X` opens a 4×4 picker; click or press the displayed grid key. | Edit `MY_EMOJIS` and `SIZE` in the entry point. |
| [Key Bindings](../Apps%20Standalone/Key%20Bindings.ahk) | Auto | Type configured hotstrings for dates, addresses, email addresses, development text, and text faces. | Several replacements use local secrets. Review this personal configuration before use. |
| [Mouse Gestures](../Apps%20Standalone/Mouse%20Gestures/Mouse%20Gestures.ahk) | Auto | Hold the configured gesture button and draw directions; defaults move, maximize, or minimize the target window. | Add mappings with `Gestures.Add(...)`; detection settings live in `Gesture Detector.ahk`. |
| [Screen Snipper](../Apps%20Standalone/Screen%20Snipper/Screen%20Snipper.ahk) | Auto | Drag with `Win+LButton` to snip and copy; add Ctrl for copy-only, Alt for save-only, or Shift for OCR-only. | Adapted from the credited AutoHotkey forum tool. `Screen Snipper OCR.ahk` supplies OCR support. |
| [Text Speaker](../Apps%20Standalone/Text%20Speaker/Text%20Speaker.ahk) | Auto | `Ctrl+Space` reads or pauses selected text; `Ctrl+Shift+drag` reads a screen region; `Ctrl+Shift+Esc` stops. | Uses Windows SAPI, OCR, and a WebView2 control panel. Local voice settings are git-ignored. |
| [Window Manager](../Apps%20Standalone/Window%20Manager.ahk) | Auto | `CapsLock` plus left/right/middle mouse drags, resizes, or closes; `CapsLock+Up` toggles always-on-top. | Requires CapsLock Service; skips configured VM windows. |

## Integrated apps

Integrated scripts either run as quiet background services or are loaded into a dashboard and called as functions.

| Script | Starts | Purpose / invocation | Notes |
|---|---|---|---|
| [App Hotkeys](../Apps%20Integrated/App%20Hotkeys.ahk) | Auto | `Win+Z` and `Win+Alt+Z` perform active-app actions for Notion, Teams, and VS Code. | Add rules with `AppSpecificHotkey.Set(...)`. Some language actions are placeholders. |
| [Command Storer](../Apps%20Integrated/Command%20Storer/Command%20Storer.ahk) | Auto | `Win+C` opens categorized, reusable commands for copying. | Its storage implementation is under `Storage/`; also exposed on the work Macro Board. |
| [Hotkeys](../Apps%20Integrated/Hotkeys.ahk) | Auto | Central app- and profile-sensitive shortcuts, including VS Code/calendar navigation and KeePass password actions. | Depends on installed apps and local secrets; review before reuse. |
| [Mouse Toys](../Apps%20Integrated/Mouse%20Toys.ahk) | Auto | Extra mouse buttons and wheel combinations control volume and profile-specific behavior. | Disabled or changed for some profiles and VM workflows. |
| [Fake Working Mode](../Apps%20Integrated/Fake%20Working%20Mode.ahk) | Loaded by dashboards | Periodically simulates activity; toggle from Macro Board or launch with Age of Efficiency command `FW`. | Enabled automatically only for its configured profile. |
| [PBI Reformat](../Apps%20Integrated/PBI%20Reformat.ahk) | Loaded by Age of Efficiency | Command `PBI` opens a listener that reformats a copied Product Backlog Item. | Work-specific clipboard utility. |
| [Picture in Picture](../Apps%20Integrated/Picture%20In%20Picture.ahk) | Loaded by Age of Efficiency | Command `P` requests picture-in-picture for a YouTube video and pins its window. | Uses browser UI Automation and the desktops DLL. |
| [Status Meme](../Apps%20Integrated/Status%20Memes/Status%20Meme.ahk) | Loaded by Age of Efficiency | Command `SC <code>` displays a matching status-code image temporarily. | Images belong under `Status Memes/Images/`; falls back to code 69. |
| [Timer](../Apps%20Integrated/Timer.ahk) | Loaded by Age of Efficiency | Command `T <minutes>` opens a task timer; `F1` starts and `Esc` hides its GUI. | Callable as `Timer.Start(...)` from other scripts. |
| [Spell Checker](../Apps%20Integrated/Spell%20Checker.ahk) | Loaded by Macro Board | Expands common Dutch and English misspellings; toggle from Macro Board. | Add corrections as AutoHotkey hotstrings. |
| [Nightlight](../Apps%20Integrated/Nightlight.ahk) | Optional include | Provides a configurable, click-through warm screen overlay. | Not in the current startup include chain; call its functions from a dashboard or hotkey. |

## App companion modules

These files support the entry points above and are not intended to run independently.

| Module | Role |
|---|---|
| [FileService.ahk](../Apps%20Integrated/Command%20Storer/Storage/FileService.ahk) | Reads, writes, adds, and removes the command-set text files. |
| [Desktop.ahk](../Apps%20Standalone/Desktops%20Manager/Desktop.ahk) | Models desktops and the windows that must be opened or activated on them. |
| [Gesture Detector.ahk](../Apps%20Standalone/Mouse%20Gestures/Gesture%20Detector.ahk) | Tracks mouse movement and converts it into directional gesture strings. |
| [Screen Snipper OCR.ahk](../Apps%20Standalone/Screen%20Snipper/Screen%20Snipper%20OCR.ahk) | Extracts text from a selected screen region. |
| [Screen Snip Speaker.ahk](../Apps%20Standalone/Text%20Speaker/Screen%20Snip%20Speaker.ahk) | Connects screen-region selection and OCR to Text Speaker playback. |
| [Notion Pages.ahk](../Apps%20Integrated/Notion%20Pages.ahk) | Defines profile-specific Notion destinations at the application boundary for Macro Board actions. |

## Dashboards and hosts

| Dashboard | Starts | Open / purpose | Data and configuration |
|---|---|---|---|
| [Age of Efficiency](../Dashboards/Age%20of%20Efficiency/Age%20Of%20Efficiency.ahk) | Auto | `Alt+Space`, `Insert`, or `Numpad Insert` opens a command launcher for apps, bookmarks, and searches. | JSON databases live under `Database/`; commands call functions under `Input Handler/`. |
| [Macro Board](../Dashboards/Macro%20Board/Macro%20Board.ahk) | Auto | `CapsLock+Space` opens a Stream Deck-style action grid. | Configure common and profile buttons in the entry point; window state is stored in the ignored profile-settings folder. |
| [Logger](../Dashboards/Logger/Logger%20Host.ahk) | Auto through logging initialization | Small notification host that surfaces new structured errors. | `Logging.ahk` is the public facade; `Controller.ahk` controls presentation. |
| [Log Dashboard](../Dashboards/Log%20Dashboard/Dashboard.ahk) | Auto through logging initialization | Open from the startup tray, Macro Board, or Age of Efficiency command `AL` to inspect and copy errors. | `Dashboard.ahk` renders `Logs/errors.log`; the active log is reset on suite startup. |
| [Test Dashboard](../Dashboards/Test%20Dashboard/Dashboard.ahk) | On demand | Choose **Test Dashboard** in the tray or run `Tests/Run-Tests.ahk` to execute and monitor checks. | Reads test status and history from `Logs/`. See [Testing](TESTING.md). |

## Startup and configuration scripts

| Area | Entry point | Responsibility |
|---|---|---|
| Suite owner | [Startup.ahk](../Startup/Startup.ahk) | Initializes configuration and launches the active app set. |
| Startup UI | [Startup Message.ahk](../Startup/Startup%20Message.ahk), [Startup Menu Tray.ahk](../Startup/Startup%20Menu%20Tray.ahk) | Shows startup feedback and provides reload, profile, dashboard, and exit controls. |
| Profiles | [Profile Manager.ahk](../Profiles/Profile%20Manager.ahk) | Detects, persists, and exposes the active machine profile. |
| Secrets | [Secrets File Manager.ahk](../Secrets/Secrets%20File%20Manager.ahk), [Secrets User Interface.ahk](../Secrets/Secrets%20User%20Interface.ahk) | Synchronizes local values with the tracked catalog and provides editing UI. |
| Compatibility imports | [Core.ahk](../Lib/Core.ahk) | Preserves a broad include facade for external or personal scripts; maintained repository files declare immediate dependencies instead. |

## Libraries and development tools

- `Lib/Apps/` contains wrappers for browsers, KeePass, MIDI Mixer, Notion, Spotify, Teams, Terminal, VS Code, and WhatsApp. These are called by apps rather than launched directly.
- `Lib/Core/`, `Lib/Extensions/`, and `Lib/Helpers/` contain shared infrastructure and utilities. Maintained files include only their immediate dependencies; see [Architecture](ARCHITECTURE.md).
- `Lib/Tools/Development Tools/` contains manually included helpers for inspecting key codes and windows and for constructing message boxes.
- `Lib/Tools/Gdip/`, `Lib/Tools/OCR/`, and `Lib/Tools/UIA-v2/` include third-party libraries, examples, and their own upstream-oriented READMEs. Examples are references, not part of suite startup or the repo test set.
- `Lib/Tools/WebView/` contains the WebView2 wrapper, loader DLLs, and a setup template used by HTML/CSS/JS interfaces.

For startup configuration and prerequisites, see [Installation](INSTALLATION.md). For the exact validation scope, see [Testing](TESTING.md).
