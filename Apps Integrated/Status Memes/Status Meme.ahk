; ============================================================================
; === Status Meme - Display status code images as notifications ===============
; ============================================================================
;
; [PURPOSE]
;   Displays humorous status code images (like HTTP status codes) as temporary
;   overlays. Used for fun notifications and status updates.
;
; [USAGE]
;   StatusMeme(200)  ; Shows image with "200" in filename
;   StatusMeme(404)  ; Shows "404" image
;   StatusMeme()     ; Prompts user for status code
;
; [FEATURES]
;   - Auto-displays for 5 seconds
;   - Click to dismiss early
;   - Rounded corners with dark theme
;   - Falls back to "69" image if code not found
;
; [SETUP]
;   Place status images in: Apps Integrated/Status Memes/Images/
;   Filename format: <code>*.jpg (e.g., 200_ok.jpg, 404_notfound.jpg)
; ============================================================================

#SingleInstance Force
#NoTrayIcon
#Include ..\..\Lib\Extensions\Dark Gui.ahk
#Include ..\..\Lib\Core\Paths.ahk
#Include ..\..\Lib\Tools\User Input.ahk

Class StatusMeme extends DarkGui {

  DISPLAY_DURATION := 5000 ; ms
  STORAGE_PATH := Paths.AppsIntegrated "\Status Memes\Images"

  __New(statusCode := "") {
    if statusCode = ""
      statusCode := UserInput().WaitForInput(false)
    
    imagePath := this._GetImagePath(statusCode)
    this._DisplayImage(imagePath)
  }

  _GetImagePath(statusCode, inRecursion := false) {
    Loop files, this.STORAGE_PATH "\*.jpg"
      if InStr(A_LoopFileName, statusCode) 
        return A_LoopFilePath

    if !inRecursion ; Prevent loop 
      return this._GetImagePath(69) ; Code not found picture
  }

  _DisplayImage(imagePath) {
    _ := super.__new("-Caption +AlwaysOnTop" , "Status Meme")
    this.BackColor := "0x000000"
    this.AddPicture("w900 h-1 x0 y0", imagePath).OnEvent("Click", (*) => this.Destroy())
    this.AddPicture("Center w900 x0 y5", this.STORAGE_PATH "\blackBoxToHideUrlInImage.PNG")
    WinSetRegion("0-0 w1130 h1000 r40-40", this)
    this.Show("w920")

    SetTimer(_DestroyGui, -this.DISPLAY_DURATION)
  
    _DestroyGui() {
      Try this.Destroy()
    }
  }
}
