# Control Deck Minimalized Icon Manifest

This folder contains the icon-only redraw of the Control Deck asset family. Backgrounds, textures, buttons, panels, cursors, illustrations, and mascot artwork are intentionally excluded.

## Visual system

- Main semantic symbol occupies roughly 76–84% of each canvas.
- Decorative hardware is limited to small, disconnected corner ticks or status pixels.
- All edges use a hard pixel grid with binary alpha; there are no anti-aliased transparency halos.
- The 96×96 icons are authored on a shared 48×48 virtual grid and enlarged 2× with nearest-neighbor sampling.
- The app emblem uses a 64×64 virtual grid; the tray icon uses a simplified 32×32 virtual grid.

## Approved palette

| Role | Hex |
| --- | --- |
| Deep black | `#090807` |
| Warm black | `#15110F` |
| Dark brown | `#241A16` |
| Raised brown | `#3A2720` |
| Dark red | `#5A191D` |
| Primary red | `#8E2C31` |
| Copper | `#B56A36` |
| Warm amber | `#D0A05A` |
| Warm ivory | `#D8C6A5` |
| Muted taupe | `#786B5C` |
| Success green | `#5FA86B` |
| Warning amber | `#D9A13B` |
| Error red | `#C94F4F` |

## Assets

| Filename | Dimensions | Purpose | Generation method |
| --- | ---: | --- | --- |
| `app-emblem.png` | 256×256 | Primary automation/command emblem | ImageGen redraw, palette snap, 64 px virtual grid |
| `tray-icon.png` | 256×256 | Simplified small-size application emblem | ImageGen redraw, palette snap, 32 px virtual grid |
| `nav-overview.png` | 96×96 | Overview navigation | ImageGen icon-first redraw, 48 px virtual grid |
| `nav-processes.png` | 96×96 | Processes navigation | ImageGen icon-first redraw, 48 px virtual grid |
| `nav-logs.png` | 96×96 | Logs navigation | ImageGen icon-first redraw, 48 px virtual grid |
| `nav-tests.png` | 96×96 | Tests navigation | ImageGen icon-first redraw, 48 px virtual grid |
| `nav-profiles.png` | 96×96 | Profiles navigation | ImageGen icon-first redraw, 48 px virtual grid |
| `nav-health.png` | 96×96 | Health navigation | ImageGen icon-first redraw, 48 px virtual grid |
| `action-reload.png` | 96×96 | Reload action | ImageGen icon-first redraw, 48 px virtual grid |
| `action-exit.png` | 96×96 | Exit/power action | ImageGen icon-first redraw, 48 px virtual grid |
| `action-run-tests.png` | 96×96 | Run tests action | ImageGen icon-first redraw, 48 px virtual grid |
| `action-notify-info.png` | 96×96 | Informational notification | ImageGen icon-first redraw, 48 px virtual grid |
| `action-notify-warning.png` | 96×96 | Warning notification | ImageGen icon-first redraw, 48 px virtual grid |
| `action-notify-error.png` | 96×96 | Error notification | ImageGen icon-first redraw, 48 px virtual grid |
| `action-start.png` | 96×96 | Start process | ImageGen icon-first redraw, 48 px virtual grid |
| `action-restart.png` | 96×96 | Restart process | ImageGen icon-first redraw, 48 px virtual grid |
| `action-stop.png` | 96×96 | Stop process | ImageGen icon-first redraw, 48 px virtual grid |
| `action-sort.png` | 96×96 | Sort list | ImageGen icon-first redraw, 48 px virtual grid |
| `action-archive.png` | 96×96 | Archive item | ImageGen icon-first redraw, 48 px virtual grid |
| `action-copy.png` | 96×96 | Copy content | ImageGen icon-first redraw, 48 px virtual grid |
| `action-open-folder.png` | 96×96 | Open folder | ImageGen icon-first redraw, 48 px virtual grid |
| `action-open-repository.png` | 96×96 | Open repository | ImageGen icon-first redraw, 48 px virtual grid |
| `action-switch-profile.png` | 96×96 | Switch profile | ImageGen icon-first redraw, 48 px virtual grid |
| `action-confirm.png` | 96×96 | Confirm action | ImageGen icon-first redraw, 48 px virtual grid |
| `action-cancel.png` | 96×96 | Cancel action | ImageGen icon-first redraw, 48 px virtual grid |
| `status-neutral.png` | 96×96 | Neutral/idle status | ImageGen state redraw, 48 px virtual grid |
| `status-info.png` | 96×96 | Informational status | ImageGen state redraw, 48 px virtual grid |
| `status-success.png` | 96×96 | Successful/passed status | ImageGen state redraw, 48 px virtual grid |
| `status-warning.png` | 96×96 | Warning status | ImageGen state redraw, 48 px virtual grid |
| `status-error.png` | 96×96 | Failed/error status | ImageGen state redraw, 48 px virtual grid |
| `status-running.png` | 96×96 | Running/testing status | ImageGen state redraw, 48 px virtual grid |
| `window-minimize.png` | 96×96 | Window minimize control | ImageGen icon-first redraw, 48 px virtual grid |
| `window-maximize.png` | 96×96 | Window maximize/restore control | ImageGen icon-first redraw, 48 px virtual grid |
| `window-close.png` | 96×96 | Window close control | ImageGen icon-first redraw, 48 px virtual grid |
| `preview-contact-sheet.png` | 1500×930 | Review sheet at 72, 32, and 24 px | Programmatic nearest-neighbor composition |

## Validation and quality notes

- 34 canonical icon files are present; all canonical icon-like filenames from `control-deck` are represented.
- All icons have transparent backgrounds and only fully transparent or fully opaque pixels.
- All visible icon pixels belong to the approved 13-color palette.
- The contact sheet confirms semantic legibility at 32×32 and 24×24.
- The `status-info` beacon intentionally uses ivory, green, and amber rather than blue to remain within the approved palette.
- These are raster production candidates. A final in-application review is still recommended because browser scaling and display DPI can change the apparent sharpness of pixel art.
