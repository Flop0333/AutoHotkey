; ============================================================================
; === Secrets Manager ========================================================
; ============================================================================
;
;   This class serves as the central repository for all application secrets (URLs, emails, API keys etc.)
;   The secrets are not tracked by git to prevent accidental sharing.
;
; [FEATURES]
;   On first access of a secret property, the user is prompted to enter the value.
;   The value is then saved to the local My Secrets.json file for future use.
;
;   The SecretsFileManager creates My Secrets.json and synchronizes it with the
;   tracked catalog during startup or on the first secret access.
;
; [SETUP]
;   1. Add a keyed Secret entry to SecretsCatalog
;      "NewSecret", Secret("Display Name", "Description")
;   2. Use it in code: Secrets.NewSecret.Get() to retrieve the value.
;      If you want the user to be prompted to set it if it's not set yet, use Secrets.NewSecret.GetOrSet() instead.
; ============================================================================

#Include ..\Lib\Tools\Info.ahk
#Include ..\Lib\Helpers\ClipSend.ahk
#Include ..\Lib\Extensions\Json.ahk
#Include ..\Lib\Core\Paths.ahk
#Include Secrets User Interface.ahk
#Include Secret.ahk
#Include Secrets Catalog.ahk
#Include Secrets File Manager.ahk

class Secrets {
    static __Get(secretKey, parameters) {
        if SecretsCatalog.Has(secretKey)
            return SecretsCatalog[secretKey]
        throw PropertyError("Unknown secret: " . secretKey)
    }
}
