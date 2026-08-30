# Action Registry Inventory

This is the migration baseline captured before and during the Action Registry implementation. “Registered” means the consumer now invokes a stable action ID through `ActionRegistry`. “Pending” means behavior is deliberately unchanged until that consumer is migrated.

Usage history is excluded from version one. The registry does not persist arguments or invocation history.

## Age of Efficiency

| Command | Stable action ID | Argument | Safety | Status |
|---|---|---|---|---|
| `FW` | `productivity.fake-work-mode.start` | None | Normal | Registered |
| `A` | `ui.age-of-efficiency.open` | None | Normal | Registered |
| `SD` | `system.shutdown` | None | Destructive confirmation | Registered |
| `RE` | `system.reload-startup` | None | Normal | Registered |
| `SC` | `development.status-meme.show` | Required status code | Normal | Registered |
| `PBI` | `development.pbi-reformat.start` | None | Normal | Registered |
| `P` | `media.picture-in-picture.start` | None | Normal | Registered |
| `V` | `development.remote-desktop.start` | Optional setting | Normal | Registered |
| `T` | `productivity.timer.start` | Required minutes | Normal | Registered |
| `Kill` | `system.kill-ahk-processes` | None | Destructive confirmation | Registered |

Command collisions are resolved by input shape: `y` and `Maps` without an argument open their bookmarks; `y <query>` and `Maps <query>` invoke their search engines.

Age of Efficiency presentation remains JSON-configurable. Its app records own the command alias and can override presentation fields, while `actionId` points to the authoritative executable behavior and safety policy.

## Macro Board

| Stable action ID | Profile | State-aware | Safety | Status |
|---|---|---:|---|---|
| `writing.spell-checker.toggle` | All | Yes | Normal | Registered |
| `system.kill-ahk-processes` | All | No | Destructive confirmation | Registered |
| `development.command-storer.open` | All | No | Normal | Registered |
| `productivity.fake-work-mode.toggle` | All | Yes | Normal | Registered |
| `system.reload-startup` | All | No | Normal | Registered |
| `notion.shit-fixen.open` | Woonkamer Laptops | No | Normal | Registered |
| `spotify.good-morning-jazz.start` | Woonkamer Laptops | No | Normal | Registered |
| `personal.finances.open` | Woonkamer Laptops | No | Normal | Registered |
| `calendar.open` | Woonkamer Laptops | No | Normal | Registered |
| `maps.open` | Woonkamer Laptops | No | Normal | Registered |
| `weather.open` | Woonkamer Laptops | No | Normal | Registered |
| `chatgpt.open` | Woonkamer Laptops | No | Normal | Registered |
| `notion.work-dashboard.open` | Work, Dev Box | No | Normal | Registered |
| `browser.close-all` | Work | No | Destructive confirmation | Registered |
| `demo.pizza` | Default | No | Normal | Registered |

Macro Board continues to own button order, profile pages, window state, and optional label/image overrides. Shared title, description, icon, state getter, availability, profiles, and safety come from registered actions.

## Binding Consumers

### Migrated global and application hotkeys

- VS Code zoom and project run/debug behavior.
- Google Calendar week navigation.
- Work KeePass password insertion.
- Notion sidebar, Teams mute, and VS Code primary/secondary app shortcuts.
- Window drag, resize, close, and always-on-top controls.
- Previous-desktop and pin-window-to-desktops controls.

The earlier Woonkamer mouse-chord shortcuts were no longer present when this phase began and were not reintroduced.

### Migrated mouse gestures

- Move window to the left monitor.
- Move window to the right monitor.
- Maximize the window under the mouse.
- Minimize the window under the mouse.

### Migrated startup tray

- Reload startup now invokes `system.reload-startup`.
- Exit now invokes `system.kill-ahk-processes` and uses the registry confirmation policy.
- Profile selection remains consumer-owned and is not an action because it dynamically constructs a menu and restarts the suite with a selected profile.

### Intentionally local bindings

- Text Speaker arrow keys are modal controls that only exist while its speaking UI is active.
- Mouse Toys wheel swaps and media-volume chords are raw input remaps rather than discoverable commands.
- Individual virtual-desktop keys capture configured `Desktop` instances at startup; only reusable previous/pin behavior is registered.
- Caps Lock service internals remain direct because they implement the modifier itself.

## Duplicate and Canonical Behaviors

- Reload buttons and tray commands should converge on `system.reload-startup`.
- Every kill-AHK entry should converge on `system.kill-ahk-processes`.
- The Macro Board’s fake-work toggle and Age of Efficiency’s start-only behavior remain distinct because they have different semantics.
- Shared Notion, Spotify, browser, calendar, maps, weather, and ChatGPT actions will be reused by hotkeys rather than redefined during hotkey migration.
- Low-level editing/navigation remaps may remain local bindings when they are not useful to any other consumer. The migration rule will be documented before hotkey cleanup.

## Regression Baseline

- Age of Efficiency continues to support commands, argument prompts, bookmarks, and searches.
- Macro Board continues to preserve profile-specific ordering, icons, tooltips, and toggle feedback.
- Registry confirmation is required for shutdown, kill-AHK, and close-all-browsers actions regardless of consumer.
- Cancelling an argument or confirmation does not fall through to another command type and is not reported as a failure.
- Missing action references report an actionable message instead of using dynamic function-name execution.
