GetScript() {
  return FileOpen(Paths.appsStandalone "\Command Storer\Storage\Command Sets\" selectedSet, "rw")
}

WriteItemToFile() {
  script := GetScript()
  script.Seek(0, 2)
  MsgBox(selectedSet)
  script.WriteLine(newKeybinding.Text "|" newCommand.Text "|" newDescription.Text)
}

DeleteItemFromFile(selectedRow) {
  script := GetScript()
  script.Seek(0, 0) ; Go to the start of the file

  ; Read the file and add the commands to the array, except the one that was deleted
  lines := []
  Loop read, Paths.appsStandalone "\Command Storer\Storage\Command Sets\" selectedSet {
      if (A_Index = selectedRow)
          continue
      lines.Push(A_LoopReadLine)
  }

  ; Delete file and write all lines back to the file in a for loop
  FileDelete(Paths.appsStandalone "\Command Storer\Storage\Command Sets\" selectedSet)
  script := GetScript() 
  for index, line in lines
    script.WriteLine(line)
}

GetLongestFileName() {
  longest := 0
  Loop Files, Paths.appsStandalone "\Command Storer\Storage\Command Sets\*.*", "FD"
  {
    if (StrLen(A_LoopFileName) > longest)
      longest := StrLen(A_LoopFileName)
  }
  return longest
}

GetMostAmountOfLines() { ; For setting the final height of ListView and Gui
  most := 0
  Loop Files, Paths.appsStandalone "\Command Storer\Storage\Command Sets\*.*", "FD"
  {
    Loop read, Paths.appsStandalone "\Command Storer\Storage\Command Sets\" A_LoopFileName
    if (A_Index > most)
      most := A_Index
  }
  return most
}
