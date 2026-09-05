Hey everyone! 👋

[![AHK Tests](https://github.com/Flop0333/AutoHotkey/actions/workflows/ahk-tests.yml/badge.svg)](https://github.com/Flop0333/AutoHotkey/actions/workflows/ahk-tests.yml)

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
- 🔊 **Text Speaker** - Select text, hit Ctrl+Space, hear it read aloud with a real neural voice (bundled, works out of the box) - with a floating Play/Pause/Restart/Volume/Speed panel
- ♾️ **And much more!**


## 🏗️ Architecture

**Profile System** - Context-aware configurations that adapt behavior per environment (work/home/laptop)

**Secrets Management** - Git-ignored file for storing personal data (emails, URLs, credentials)

**Dashboards** - WebView2-powered UIs combining modern web technologies with AHK backend

**Apps Integrated** - Background services that run continuously and integrate via hotkeys

**Apps Standalone** - Independent utilities that can run separately (Window Manager, Command Storer, etc.) 

**Bundled third-party software** - Text Speaker vendors the [Piper](https://github.com/rhasspy/piper) TTS engine (MIT) and a voice model (MIT) directly in the repo under `Lib/Tools/Piper/`, so it sounds good on a fresh clone with no setup. See [NOTICE.md](Lib/Tools/Piper/NOTICE.md) there for what's bundled, why an archived release was chosen deliberately over the actively maintained (but GPL + Python-dependent) successor, and full licensing details.


## 💭 Philosophy
Every component is modular, following OOP/SOLID principles and build with care for maximum flexibility and maintainability.

This project embraces **code-first configuration** - sometimes editing code is faster (and more fun) than clicking through UIs.



I can't wait to hear your thoughts, feedback & bug reports.
Let me know what you think! 💭

Discord Post: [https://discord.com/channels/115993023636176902/1471948793359630479]
