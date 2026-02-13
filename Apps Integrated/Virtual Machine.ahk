; ============================================================================
; === Virtual Machine - Remote Desktop connection launcher ====================
; ============================================================================
;
; [PURPOSE]
;   Quick launcher for pre-configured Remote Desktop Protocol (RDP) connections.
;   Simplifies access to multiple remote machines with preset configurations.
;
; [USAGE]
;   VirtualMachine.StartRemoteDesktop("H3")  ; Home machine 3
;   VirtualMachine.StartRemoteDesktop("K2")  ; Office machine 2
;
; [SETTINGS]
;   H2: Home 2.rdp
;   H3: Home 3.rdp (default)
;   K2: Kantoor (Office) 2.rdp
;   K3: Kantoor (Office) 3.rdp
;
; [SETUP]
;   Place .rdp files in: Documents/Remote Desktops/
; ============================================================================

class VirtualMachine {

    static StartRemoteDesktop(setting := "H3") {
        REMOTE_DESKTOPS_SETTINGS_PATH := A_MyDocuments "/Remote Desktops/"
        settingsFile := unset

        if setting = "H2"
            settingsFile := "Home 2.rdp"
        if setting = "H3"
            settingsFile := "Home 3.rdp"
        if setting = "K2"
            settingsFile := "Kantoor 2.rdp"
        if setting = "K3"
            settingsFile := "Kantoor 3.rdp"

        Run(REMOTE_DESKTOPS_SETTINGS_PATH settingsFile)
    }
}