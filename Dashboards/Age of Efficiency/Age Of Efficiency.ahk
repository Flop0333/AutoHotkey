; ============================================================================
; Age of Efficiency - AutoHotkey Command Launcher
; ============================================================================
;
; A powerful command input launcher for bookmarks, custom apps, and web searches.
;
; [FEATURES]
;   - Launch bookmarks, execute custom app code, and perform web searches
;   - Intuitive UI for managing and configuring commands
;   - JSON-based database for persistent storage
;
; [USAGE]
;   - Hotkeys: Alt+Space, Insert, or Numpad Insert to open command input
;   - Type commands and press Enter to execute
;   - Use arguments by typing the command followed by a space and the argument ("y cats" does search for cats on youtube)
;   - Access UI via 'A' command
;
; [SETUP]
;   - Run this script to start Age of Efficiency
;   - Configure items through the user interface
; ============================================================================

#Include ..\..\Lib\Core.ahk
#Include User Interface\Controller.ahk
#Include Input Handler\Command Input.ahk

USER_INTERFACE_PATH := Paths.dashboards "\Age of Efficiency\User Interface"
TraySetIcon(USER_INTERFACE_PATH "\Library\Icons\Icon.png")

!space::    CommandInput().WaitForInputAndExecute() ; Woonkamerlaptop
Insert::	CommandInput().WaitForInputAndExecute() ; Desktop
NumpadIns::	CommandInput().WaitForInputAndExecute() ; Laptop

aoeWindow := UserInterface()

A_TrayMenu.Delete()
A_TrayMenu.Add("Reload", (*) => Reload())
A_TrayMenu.Add()
A_TrayMenu.Add("Open Terminal: Insert", (*) => CommandInput().WaitForInputAndExecute())
A_TrayMenu.Disable("Open Terminal: Insert")
A_TrayMenu.Add()
A_TrayMenu.Add("Open Age of Efficiency: 'AoE'", (*) => aoeWindow.Show())
A_TrayMenu.Disable("Open Age of Efficiency: 'AoE'")