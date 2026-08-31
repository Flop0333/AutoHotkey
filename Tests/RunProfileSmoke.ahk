#Requires AutoHotkey v2
#Include ..\Startup\Startup.ahk

if A_Args.Length != 1
    throw ValueError("RunProfileSmoke requires one profile display name")

requestedName := A_Args[1]
selectedProfile := ""
for candidate in ProfileManager.allProfiles
    if candidate.displayName = requestedName {
        selectedProfile := candidate
        break
    }

if selectedProfile = ""
    throw ValueError("Unknown profile: " requestedName)

RunStartup(selectedProfile, false)
ExitApp(0)
