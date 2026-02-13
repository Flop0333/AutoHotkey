# Installation Guide

## Quick Start

1. **Clone the repository** to any folder you want

2. **Configure Secrets** (Required)
   - Navigate to `Secrets/`
   - Copy `Secrets Example.ahk` → `Secrets.ahk`
   - Fill in your personal values (optional)

3. **Run the startup script**
   ```
   Startup/Startup.ahk
   ```

4. **Optional:** Create a shortcut in Windows Startup folder for auto-launch

## Customization

### Profile Configuration
Customize behavior per computer:
- Get your computer name: `MsgBox(A_ComputerName)`
- Edit `Profiles/Profile Manager.ahk` to add your profile

### App Configuration
Review and customize these files before use:

| File | Purpose |
|------|--------|
| `Apps Integrated/Hotkeys.ahk` | App-specific hotkey behavior |
| `Apps Standalone/Key Bindings.ahk` | Global keyboard shortcuts |
| `Dashboards/Macro Board/Macro Board.ahk` | Custom macro buttons |
| `Apps Standalone/Desktops Manager/Desktops Manager.ahk` | Virtual desktop layouts |
| `Apps Standalone/Mouse Gestures/Mouse Gestures.ahk` | Gesture actions |
| `Startup/Startup.ahk` | Which apps launch automatically |

## Troubleshooting

**Scripts not working?**
- Ensure AutoHotkey v2 is installed
- Check file paths match the expected Documents location
- Verify `Secrets.ahk` exists in `Secrets/`

**Need Help?**
- Open an issue or reach out directly
- Contributions and feedback welcome!

Happy automating! 🚀
