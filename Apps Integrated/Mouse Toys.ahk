; ============================================================================
; === Mouse Toys - Custom mouse button and wheel actions =====================
; ============================================================================

#Include <Core>
#Include <Core\SafeCall>
A_MaxHotkeysPerInterval := 420


~XButton2 & WheelDown:: {
    VolumeDownHandler() {
        If GetKeyState("XButton2","P")
Send("{Volume_Down}")
        
    }
    SafeCall("mouse_toys.volume_down", (*) => GetKeyState("XButton2", "P") ? Send("{Volume_Down}") : "", { serviceId: "mouse_toys" })
    SafeCall("mouse_toys.volume_down", VolumeDownHandler(), { serviceId: "mouse_toys" })
}

~XButton2 & WheelUp:: {

}

#HotIf !ProfileManager.Is(Profiles.devbox) ; Disable mouse toys on devbox to prevent interference with VM workflow
; Revert horizontal scrolling wheel
WheelLeft:: WheelRight
WheelRight:: WheelLeft

#HotIf ProfileManager.Is(Profiles.woonkamerLaptops)
; Manage Volume with Left Mouse Button + Scroll
~RButton & WheelDown:: {

}

~RButton & WheelUp:: {

}