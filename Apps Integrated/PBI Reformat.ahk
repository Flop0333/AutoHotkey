; ============================================================================
; === PBI Reformat - Reformats copied Product Backlog Items for dev use ======
; ============================================================================

#Include ..\Lib\Core.ahk

Class PBIReformat {

    static reformatGui := DarkGui

    static Start() {
        this.reformatGui := DarkGui("+AlwaysOnTop -MinimizeBox -MaximizeBox", "Please copy PBI")
        this.reformatGui.OnEvent("Close", (*) => OnClipboardChange(ClipboardChange, 0)) ; Unregister clipboard change on close
        this.reformatGui.Show("w400 h200")

        OnClipboardChange(ClipboardChange)
        Return

        ClipboardChange(type) {
            if type != 1
                return
            restult := this.ReformatPbi()
            if !restult
                return
            A_Clipboard := restult
            this.TransformGuiAfterReformat() 
        }
    }


    static ReformatPbi() {
        oldPrefixes := Map("Product Backlog Item", "feature/", "Bug", "bugfix/")
        
        for oldPrefix, newPrefixValue in oldPrefixes { ; Set new prefix based on old prefix
            if (InStr(SubStr(A_Clipboard, 1, 20), oldPrefix)) {
                trimmedText := StrReplace(LTrim(A_Clipboard, oldPrefix), ":")
                newPrefix := newPrefixValue
                break
            } 
        } 
        if !IsSet(newPrefix) {
            MsgBox("The copied text does not start with a recognized PBI prefix.", "Error", 0x40000)
            Return false
        }
        cleanUpText := RegExReplace(trimmedText, "[^a-zA-Z0-9\s]", "") ; Remove anything but letters, numbers, and spaces
        
        Loop parse, cleanUpText, A_Space ; Insert dashes between words and before capital letters
            finalText .= RegExReplace(A_LoopField, "([a-z\d])([A-Z])", "$1-$2") . "-" ; Get each word and add a -
        
        Sleep 50

        if (SubStr(finalText, 1, 1) = "-") ; Check if first character is a '-'
            Return newPrefix . SubStr(finalText, 2, -1) ; Remove the first and last dashes
        else 
            Return newPrefix . SubStr(finalText, 1, -1) ; Remove  last dash
    }

    static GetStringWithLineBreaks(longString) {
        maxLength := 40  
        moreCharactersToSplit := true

        While (moreCharactersToSplit) {
            Piece := SubStr(longString, 1, maxLength)
            longString := SubStr(longString, maxLength + 1)
            Result .= Piece
            moreCharactersToSplit := StrLen(longString) > 0 ? (Result .= "`n", true) : false
        }
        Return "Copied to clipboard:`n" Result
    }

    static TransformGuiAfterReformat() {
        this.reformatGui.Hide()
        this.reformatGui.SetFont("s13 italic")
        this.reformatGui.Title := "All done!"
        this.reformatGui.Opt("-AlwaysOnTop")
        this.reformatGui.AddText("x10 y60 w380", this.GetStringWithLineBreaks(A_Clipboard))
        this.reformatGui.AddProgress("x0 y10 w400 h20 cBlue vMyProgress", 100)
        this.reformatGui.Show("w400 h200")

        count := 40
        Loop 100 {
            Sleep(count -= 0.25)
            this.reformatGui["MyProgress"].Value -= 1
        }
        ExitApp
    }

    static ExitAppWhenClosingGui(*) {
        this.reformatGui.Destroy()
    }
}
