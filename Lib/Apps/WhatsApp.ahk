#Include App.ahk
#Include ..\Tools\UIA-v2\Lib\UIA.ahk
#Include ..\Tools\Info.ahk

Class WhatsApp extends App {
    static __New() => this.Init(
		winTitle := "WhatsApp",
		ahk_exe := "WhatsApp.exe",
        path := A_AppData "\Microsoft\Windows\Start Menu\Programs\WhatsApp.lnk"
	)

    ; Overwrite the default Launch() method to launch WhatsApp from the Windows Apps folder
    static Launch() {
        ; get the app's path from the Windows Apps folder and run it
        ; Get-StartApps | Where-Object { $_.Name -match "WhatsApp" }
        appsFolderPrefix := "shell:AppsFolder\"
        appId := ""
        if (A_ComputerName = "floplaptop") 
            appId := "5319275A.WhatsAppDesktop_cv1g1gvanyjgm!App"


        try Run(appsFolderPrefix appId)
        catch  
            Info("appId for this computer not set! Set it in WhatsApp.ahk", timeout := 5000)
            return
    }
}
