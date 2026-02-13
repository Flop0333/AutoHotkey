; ============================================================================
; === Capslock Service - Global CapsLock Modifier Handler ===================
; ============================================================================
;
; [OVERVIEW]
;  Background service that converts CapsLock into a powerful modifier key
;  while preserving its original toggle functionality via double-tap.
;
; [IMPORTANT]
; - Must run BEFORE any script that uses Capslock.Hotkey()
; - Auto-started by main startup script
; - Runs as a background service with no tray icon
;
; [FEATURES]
; - Single press: Acts as modifier key for custom hotkeys
; - Double-tap: Toggles CapsLock state (original functionality)
; - Auto-focus host when pressed in VM (prevents hotkey capture)
; - Integration with Desktops Manager for seamless VM workflows
; ============================================================================

#Include ..\Lib\Tools\Info.ahk
#SingleInstance Force
#NoTrayIcon

CapsLock:: {
   EnsureHostFocus()                              ; Always return focus to host if in VM
   KeyWait('CapsLock')                               ; wait for Capslock to be released
   if (A_TimeSinceThisHotkey < 200)                  ; in 0.2 seconds
   and KeyWait('CapsLock', 'D T0.2')                 ; and pressed again within 0.2 seconds
   and (A_PriorKey = 'CapsLock')                     ; block other keys
      SetCapsLockState !GetKeyState('CapsLock', 'T')
}
*CapsLock:: Send '{Blind}{vk07}'                     ; This forces capslock into a modifying key & blocks the alt/start menus

; Ensures host desktop regains focus if CapsLock is pressed while in a VM window.
; Used with Desktops Manager to prevent hotkeys from being trapped in the VM.
EnsureHostFocus() {
   virtualMachineClass := "ahk_class TscShellContainerClass"
    if WinActive(virtualMachineClass)
      WinActivate("ahk_class Shell_TrayWnd") ; Activate the taskbar of the host
}