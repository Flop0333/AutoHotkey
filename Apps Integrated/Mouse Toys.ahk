; ============================================================================
; === Mouse Toys - Custom mouse button and wheel actions =====================
; ============================================================================

#Include ..\Lib\Core.ahk
#Include ..\Lib\Core\SafeCall.ahk
A_MaxHotkeysPerInterval := 420


~XButton2 & WheelDown:: {
    SafeCall("mouse_toys.volume_down", (*) => GetKeyState("XButton2", "P") ? Send("{Volume_Down}") : "", {serviceId: "mouse_toys"})
}

~XButton2 & WheelUp:: {
    SafeCall("mouse_toys.volume_up", (*) => GetKeyState("XButton2", "P") ? Send("{Volume_Up}") : "", {serviceId: "mouse_toys"})
}

#HotIf !ProfileManager.Is(Profiles.devbox) ; Disable mouse toys on devbox to prevent interference with VM workflow
; Revert horizontal scrolling wheel
WheelLeft:: WheelRight
WheelRight:: WheelLeft

#HotIf ProfileManager.Is(Profiles.woonkamerLaptops)
; Manage Volume with Left Mouse Button + Scroll
~RButton & WheelDown:: {
    SafeCall("mouse_toys.right_volume_down", (*) => GetKeyState("RButton", "P") ? Send("{Volume_Down}") : "", {serviceId: "mouse_toys"})
}

~RButton & WheelUp:: {
    SafeCall("mouse_toys.right_volume_up", (*) => GetKeyState("RButton", "P") ? Send("{Volume_Up}") : "", {serviceId: "mouse_toys"})
}
