# AHK Control Deck V2 asset manifest

This second asset kit replaces the first direction with denser, easier-to-read pixel art and a black, brown, and dark-red hardware identity. It contains no mascot or character artwork. The existing dashboard frontend was inspected to cover its actual navigation, status, process, log, test, profile, health, confirmation, and title-bar controls. No dashboard source file was edited.

## Palette

- near-black `#090807`
- warm black `#15110F`
- dark brown `#241A16`
- brown `#3A2720`
- dark oxblood `#5A191D`
- red highlight `#8E2C31`
- copper `#B56A36`
- brass `#D0A05A`
- warm ivory `#D8C6A5`
- muted taupe `#786B5C`
- success green `#5FA86B`
- warning amber `#D9A13B`
- error red `#C94F4F`

Every visible runtime pixel is restricted to this palette. Transparent icons and buttons use hard alpha. `screen-texture.png` intentionally uses low partial alpha.

## Branding

| File | Size | Purpose |
| --- | ---: | --- |
| `app-emblem.png` | 256×256 | Detailed command-console, keyboard-input, and automation emblem. |
| `tray-icon.png` | 256×256 | Simplified emblem for 16px and 32px tray use. |

## Navigation

All navigation assets are 96×96 transparent PNGs built on a denser 48×48 virtual grid and intended for display around 32px.

| File | Dashboard destination |
| --- | --- |
| `nav-overview.png` | Overview |
| `nav-processes.png` | Processes |
| `nav-logs.png` | Logs |
| `nav-tests.png` | Tests |
| `nav-profiles.png` | Profiles |
| `nav-health.png` | Health |

## Actions and window controls

All action assets are 96×96 transparent PNGs using the same 48×48 grid, frame weight, and lighting.

| File | Dashboard use |
| --- | --- |
| `action-reload.png` | Reload the suite. |
| `action-exit.png` | Exit the suite. |
| `action-run-tests.png` | Run all tests. |
| `action-notify-info.png` | Send a test information notification. |
| `action-notify-warning.png` | Send a test warning notification. |
| `action-notify-error.png` | Send a test error notification. |
| `action-start.png` | Start a stopped process. |
| `action-restart.png` | Restart a process. |
| `action-stop.png` | Stop a process. |
| `action-sort.png` | Change log sort order. |
| `action-archive.png` | Open archived sessions. |
| `action-copy.png` | Copy log or test details. |
| `action-open-folder.png` | Open logs or archive folders. |
| `action-open-repository.png` | Open the repository. |
| `action-switch-profile.png` | Activate a different profile. |
| `action-confirm.png` | Confirm an operation. |
| `action-cancel.png` | Cancel or dismiss an operation. |
| `window-minimize.png` | Minimize the dashboard. |
| `window-maximize.png` | Maximize or restore the dashboard. |
| `window-close.png` | Close the dashboard window. |

## Semantic states

Each state symbol is a 96×96 transparent PNG. Shape and color both change so meaning does not depend on color alone.

| File | State |
| --- | --- |
| `status-neutral.png` | Neutral, unavailable, or not run. |
| `status-info.png` | Informational. |
| `status-success.png` | Healthy, active, installed, or passed. |
| `status-warning.png` | Warning, partial, missing, or busy. |
| `status-error.png` | Error or failed. |
| `status-running.png` | Sampling, loading, or tests currently running. |

## Button assets

All buttons are 320×80 transparent PNGs. The generic files contain no text or icon so the dashboard can overlay accessible HTML labels. The four test controls contain exact state text as specifically requested.

| File | State or label |
| --- | --- |
| `button-generic-normal.png` | Normal button surface. |
| `button-generic-hover.png` | Hovered surface. |
| `button-generic-pressed.png` | Pressed or selected surface. |
| `button-generic-disabled.png` | Disabled surface. |
| `button-generic-warning.png` | Warning action surface. |
| `button-generic-destructive.png` | Destructive action surface. |
| `button-tests-run.png` | `RUN TESTS` |
| `button-tests-running.png` | `TESTING...` |
| `button-tests-passed.png` | `TESTS PASSED` |
| `button-tests-failed.png` | `TESTS FAILED` |

## Materials and review

| File | Size | Purpose |
| --- | ---: | --- |
| `background-tile.png` | 256×256 | Seamless low-contrast machine-casing texture. |
| `screen-texture.png` | 256×256 | Seamless low-alpha scanline and phosphor overlay. |
| `panel-plate.png` | 256×256 | Detailed inset plate for cards, dialogs, or detail panes. |
| `preview-contact-sheet.png` | 1800×1400 | Full kit review at intended interface sizes. Not a runtime asset. |

## Generation and verification

The visual sources were produced with the built-in OpenAI ImageGen tool. Related controls were generated as tightly aligned family atlases to preserve consistent lighting and geometry, then exported as individual files. A deterministic post-process removed generator backdrops, snapped colors to the palette, normalized icons on a 48×48 virtual grid, used nearest-neighbor enlargement, added the exact test-state labels, and enforced final canvases.

Validation completed successfully:

- 48 PNG files present with the expected dimensions;
- no mascot or character assets present;
- all runtime pixels belong to the documented palette;
- hard alpha on icons and buttons;
- partial alpha limited to the screen overlay;
- matching opposite edges on both seamless textures;
- exact test-button text visually reviewed on the contact sheet.
