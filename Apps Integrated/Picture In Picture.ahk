; ============================================================================
; === Picture In Picture - Enables picture-in-picture mode for videos ========
; ============================================================================

#Include ..\Lib\Core.ahk
#Include ..\Lib\Core\UIA.ahk

StartPictureInPicture() => PictureInPicture()

PictureInPicture() {
    jsCode := "(()=>{const video=document.querySelector('video');if(video&&document.pictureInPictureEnabled){video.requestPictureInPicture();}})();"
    
    cUIA := UIA_Browser("YouTube")
    cUIA.JSExecute(jsCode)
    
    WinWait("Picture in picture",, 3) ; Seconds
    if WinExist("Picture in picture") {
        DesktopsDDL.TogglePin(WinGetID("Picture in picture"))
        WinMove(420,400,1132,637,"Picture in picture")
    }
    WinActivate(cUIA.BrowserId)
}