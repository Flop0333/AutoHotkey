Hey everyone! 👋

I'm excited to show my AutoHotkey v2 workflow system that I've been building! It's a modular collection of productivity tools that's transformed how I work.

**New to this project?** → [Installation Guide](INSTALLATION.md)

## ✨ Features

### Core Tools
- 🖥️ **Virtual Desktops Manager** - Seamlessly auto-launch apps per virtual desktop
- 🪟 **Window Manager** - Drag, resize & control windows with CapsLock shortcuts
- ⌨️ **CapsLock Modifier** - Repurpose CapsLock as a powerful modifier key
- 🖱️ **Mouse Gestures** - Execute quick actions with mouse movements


### Dashboards
- 🚀 **Age of Efficiency** - Command launcher for bookmarks, searches, and scripts
![alt text](<Dashboards/Age of Efficiency/Demo.gif>)

- 🎹 **Macro Board** - Stream Deck-like interface with customizable buttons
![alt text](<Dashboards/Macro Board/Demo.gif>)


### Productivity Apps
- 📸 **Screen Snipper with OCR** - Capture and extract text from screens in seconds
- 🐭 **Mouse Gestures** - Execute quick actions with mouse movements 
- 🪟 **Window Management** - Drag, resize & control windows with CapsLock shortcuts
- 🧑‍💻 **Command Storer** - Quick access to frequently used commands
- 🤓 **Emoji Sender** - Quick emoji picker with keyboard shortcuts
- ⌨️ **Capslock Modifier** - Capslock as powerful modifier key
- ♾️ **And much more!**


## 🏗️ Architecture

**Profile System** - Context-aware configurations that adapt behavior per environment (work/home/laptop)

**Secrets Management** - Git-ignored file for storing personal data (emails, URLs, credentials)

**Dashboards** - WebView2-powered UIs combining modern web technologies with AHK backend

**Apps Integrated** - Background services that run continuously and integrate via hotkeys

**Apps Standalone** - Independent utilities that can run separately (Window Manager, Command Storer, etc.) 

### Action Registry

Reusable behavior is identified by stable action IDs and registered through the central Action Registry. Dashboards, hotkeys, gestures, tray menus, and desktop layouts reference those IDs instead of directly calling each other's functions. The registry consistently applies profile rules, availability, arguments, confirmations, state reading, safe failure handling, and bounded metadata-only logging.

Canonical definitions live in `Lib/Actions/Modules`. These files are inert factories: including one does not execute an action or create a consumer. The application that owns the real callable registers the definition and its interfaces reference the stable ID.

To add or expose an action, follow the [Action Registry Guide](docs/Action%20Registry%20Guide.md). Existing ID changes and intentional compatibility differences are recorded in the [migration notes](docs/Action%20Registry%20Migration.md).

For validation, run `Tests/RunRegistryTests.ahk`, `Tests/ValidateActionReferences.ps1`, and the applicable `Tests/Compile*.ahk` harness.


## 💭 Philosophy
Every component is modular, following OOP/SOLID principles and build with care for maximum flexibility and maintainability.

This project embraces **code-first configuration** - sometimes editing code is faster (and more fun) than clicking through UIs.



I can't wait to hear your thoughts, feedback & bug reports.
Let me know what you think! 💭

Discord Post: [https://discord.com/channels/115993023636176902/1471948793359630479]
