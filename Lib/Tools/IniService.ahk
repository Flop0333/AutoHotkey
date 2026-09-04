; ============================================================================
; === INI Service ============================================================
; ============================================================================
;
; [USAGE]
;   ini := IniService("path\to\file.ini")
;   value := ini.SectionName.KeyName
;   ini.SectionName.KeyName := "Value
;   ini.CreateSection("Settings").AddKeyValue("Settings", "Volume", "75")
;   ini.SaveFile()
; ============================================================================


class IniService {

    __New(filePath) {
        this.filePath := filePath
        
        ; Create parent directory if it doesn't exist
        SplitPath filePath,, &dir
        if dir && !DirExist(dir)
            DirCreate(dir)
        
        this.LoadFile(filePath)

        ; if file doesn't exist, create default settings from class properties 
        if !FileExist(filePath)
            this.ReconstructIniFile()
    }

    ReconstructIniFile() {
        ; Override in subclass to create default ini structure
    }

    LoadFile(filePath) {
        if (!FileExist(filePath)) 
            return

        currentSection := ""
        loop Parse, FileRead(filePath), "`n", "`r"
        {
            trimmedLine := Trim(A_LoopField)

            if (trimmedLine = "" || SubStr(trimmedLine, 1, 1) = ";") ; Ignore blank lines and comments
                continue

            if (SubStr(trimmedLine, 1, 1) = "[" && SubStr(trimmedLine, -1) = "]") { ; Handle Section
                currentSection := SubStr(trimmedLine, 2, -1)
                this.DefineProp(currentSection, {Value: Map()})
                continue
            }
            pos := InStr(trimmedLine, "=") ; Handle Key & Value
            if (pos) {
                key := Trim(SubStr(trimmedLine, 1, pos - 1))
                value := Trim(SubStr(trimmedLine, pos + 1))
                this.%currentSection%.DefineProp(key, {Value: value})
            }
        }
    }

    SaveFile() {
        ; Build file content
        ; If file doesn't exist, auto create sections and keys from class properties
        fileContent := ""
        for sectionName, sectionValueMap in this.OwnProps() {
            
            if (sectionName = "filePath" || sectionName = "base")
                continue

            ; Skip properties that are not Maps (not INI sections)
            if (Type(sectionValueMap) != "Map")
                continue

            fileContent .= "[" sectionName "]`n" ; Add section
            for key, value in sectionValueMap.OwnProps() 
                fileContent .= key "=" value "`n" ; Add keys & values

            fileContent .= "`n" ; Linebreak between sections
        }

        ; Write to a temp file first and rename over the destination, so a crash mid-write
        ; can never leave the ini file deleted or half-written.
        tempPath := this.filePath . "." . A_TickCount . ".tmp"
        try {
            try FileDelete(tempPath)
            FileAppend(fileContent, tempPath)
            FileMove(tempPath, this.filePath, true)
        } catch {
            MsgBox("could not save " this.filePath)
        }
    }

    CreateSection(section) {
        this.DefineProp(section, {Value: Map()})
        return this
    }

    AddKeyValue(section, key, value) {
        this.%section%.DefineProp(key, {Value: value})
        return this
    }
}