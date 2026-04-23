; ============================================================================
; === Mouse Toys - Custom mouse button and wheel actions =====================
; ============================================================================

#Include ..\Lib\Core.ahk
A_MaxHotkeysPerInterval := 420


~XButton2 & WheelDown:: {
    If GetKeyState("XButton2", "P")
        Send("{Volume_Down}")
}

~XButton2 & WheelUp:: {
    If GetKeyState("XButton2", "P")
        Send("{Volume_Up}")
}

#HotIf !ProfileManager.Is(Profiles.devbox) ; Disable mouse toys on devbox to prevent interference with VM workflow
; Revert horizontal scrolling wheel
WheelLeft:: WheelRight
WheelRight:: WheelLeft

#HotIf ProfileManager.Is(Profiles.woonkamerLaptops)
; Manage Volume with Left Mouse Button + Scroll
~RButton & WheelDown:: {
    If GetKeyState("RButton", "P")
        Send("{Volume_Down}")
}

~RButton & WheelUp:: {
    If GetKeyState("RButton", "P")
        Send("{Volume_Up}")
}