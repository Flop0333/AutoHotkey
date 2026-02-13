; ============================================================================
; === Command Storer - Organize and quickly access frequently used commands ==
; ============================================================================
;
; [FEATURES]
; - Store commands in organized sets (e.g., Powershell, Git, Docker)
; - Single-click to copy commands to clipboard
; - Double-click to copy and close the GUI
; - Add/delete commands and command sets
; - Assign keybindings and descriptions to commands
;
;  [HOTKEYS]
;   Win + C - Opens the Command Storer GUI
;
; Note: This was built a long time ago, it could use some improvements **
; ============================================================================

#SingleInstance Force
#Include ..\..\Lib\Tools\User Input.ahk
#Include ..\..\Lib\Extensions\Dark Gui.ahk
#Include Storage\FileService.ahk
TraySetIcon("icon.png")

scriptName := StrSplit(A_ScriptName, '.ahk')[1]

global DEFAULT_SET := "Powershell"

#C:: WinExist(scriptName) ? WinActivate() : ShowMainGui()

Class CommandStorer {

    static __New() {
        this._SetupTrayMenu_()
    }
    
    static _SetupTrayMenu_() {
        A_TrayMenu.Delete()
        A_TrayMenu.Add("Open Editor",   (*) => WinExist(scriptName) ? WinActivate() : ShowMainGui())
        A_TrayMenu.Add()
        A_TrayMenu.Add("Exit",   (*) => ExitApp())
        A_TrayMenu.Add()
        A_TrayMenu.Add("Win + C",  (*) => WinExist(scriptName) ? WinActivate() : ShowMainGui())
        A_TrayMenu.Disable("Win + C")
    }
}

CreateSet(*) {
    newSet := UserInput().WaitForInput()
    if (newSet = "")
        return
    FileOpen("Storage\Command Sets\" newSet ".txt", "rw")
    mainGui.Destroy()
    ShowMainGui()
}

DeleteSet(*) {
    fileName := StrReplace(selectedSet, ".txt", "")
    if (!IsSet(selectedSet))
      return MsgBox("Select a set", "Error", "Iconi T1")
  
    Result := MsgBox("Delete " fileName " set?", "Warning", "YesNo")
    if Result = "No"
        Return
  
    Result := MsgBox("Absolutely sure?", "Delete " fileName " set?", "YesNo")
    if Result = "No"
        Return
  
    FileDelete("Storage\Command Sets\" selectedSet)
    Reload()
  }

AddAllSetButtons() {
    Loop Files, "Storage\Command Sets\*.*", "FD"
            AddSingleSetButton(A_LoopFileName)
}
 
AddSingleSetButton(file) { ; This extra method is needed to keep the value of A_LoopFileName
    fileName := StrReplace(A_LoopFileName, ".txt", "")
    newYPosition := BUTTON_START_POS_Y + (A_Index * BUTTON_Y_MULTIPLY_FACTOR)
    mainGui.AddButton("x" BUTTON_START_POS_X " y" newYPosition, fileName).OnEvent("Click", (*) => InsertCommandsToListView(file, fileName))
}

InsertCommandsToListView(file, fileName){
    global selectedSet := file
    listView.ModifyCol(3,,fileName) ; Set the Set name as the header
    listView.Delete()
    
    Loop Files, "Storage\Command Sets\*.*", "FD" ; Look for the file
        if (A_LoopFileName = file) {
            Loop read, "Storage\Command Sets\" file { ; Read the file and add the commands to the listview
                keybinding := StrSplit(A_LoopReadLine, "|")[1]
                command := StrSplit(A_LoopReadLine, "|")[2]
                descreption := StrSplit(A_LoopReadLine, "|")[3]
                listView.Add(, keybinding, command, descreption)   
            }
        }
}

AddItem(*) {
    if (ShowMessageOnInvalidNewItemInput()) 
        return
    if (newKeybinding.Text = "keybinding")
        newKeybinding.Text := " "
    WriteItemToFile()

    ; Reset the input fields and add the new item to the listview
    listView.Add(, newKeybinding.Text, newCommand.Text, newDescription.Text)
    newKeybinding.Text := "keybinding"
    newDescription.Text := "description"
    newCommand.Text := "command"
}

ShowMessageOnInvalidNewItemInput() {
    if (newDescription.Text = "description" || newCommand.Text = "command") 
        return MsgBox("Insert a description and command", "Error", "Iconi T1")
    
    if (!IsSet(selectedSet))
        return MsgBox("Select a set", "Error", "Iconi T1")
}

DeleteItemCommand(*) {
    try selectedRow := listView.GetNext(0)
    if selectedRow {
        DeleteItemFromFile(selectedRow)
        listView.Delete(selectedRow) 
    }

}
CopyCommandOnSingleClick(LV, RowNumber) {
    ToolTip() ; Remove the previous tooltip
    A_Clipboard := LV.GetText(RowNumber, 2)
    sleep 200
    global tip := Tooltip("Copied: " A_Clipboard)
    SetTimer(ToolTip, -1800)
}
CopyCommandOnDoubleClick(LV, RowNumber) {
    A_Clipboard := LV.GetText(RowNumber, 2)
    mainGui.Destroy()
    ; ShowMainGui()
}

; Gui Varriables
global LISTVIEW_START_X := 30 ; start position of the listview
global LISTVIEW_START_Y := 60
global BUTTON_START_POS_X := 1200 + LISTVIEW_START_X ; start position of the buttons
global BUTTON_START_POS_Y := 71 + LISTVIEW_START_Y
global BUTTON_Y_MULTIPLY_FACTOR := 53 ; distance between buttons
global FINAL_WIDTH := BUTTON_START_POS_X + 200 + (GetLongestFileName() * 12)
global LISTVIEW_OPTIONS := " h540 w1170 cblack Grid 0x8000 0x4 0x10" ; disable header, only one item can be selected
global selectedSet

ShowMainGui(){
    global mainGui := DarkGui("-Caption" , "Eazy Commands").fontSize(12)
    mainGui.SetFont("italic")
    global newKeybinding := MainGui.AddEdit("x" LISTVIEW_START_X + 147 " y" LISTVIEW_START_Y - 42 " w100 h27", "keybinding")
    global newCommand := MainGui.AddEdit("x" LISTVIEW_START_X + 147 " y" LISTVIEW_START_Y " w300 h27", "command")
    global newDescription := MainGui.AddEdit("x" LISTVIEW_START_X + 147 " y" LISTVIEW_START_Y + 42 " w420 h27", "description")
    mainGui.AddButton("x" LISTVIEW_START_X+1010 " y" LISTVIEW_START_Y " w120 h27", "Add Set").OnEvent("Click", CreateSet)
    mainGui.AddButton("x" LISTVIEW_START_X+1010 " y" LISTVIEW_START_Y+42 " w120 h27", "Delete Set ").OnEvent("Click", DeleteSet)
    mainGui.AddButton("x" LISTVIEW_START_X " y" LISTVIEW_START_Y " w120 h27", "Add Item").OnEvent("Click", AddItem)
    mainGui.AddButton("x" LISTVIEW_START_X " y" LISTVIEW_START_Y+42 " w120 h27", "Delete Item").OnEvent("Click", DeleteItemCommand)
    
    mainGui.SetFont("s15")
    mainGui.SetFont("norm")
    global listView := mainGui.AddListView("x" LISTVIEW_START_X " y" LISTVIEW_START_Y + 87  LISTVIEW_OPTIONS, ["keybinding", "Command", "Description"])
    listView.Opt("-Sort")
    listView.OnEvent("Click", CopyCommandOnSingleClick)
    listView.OnEvent("DoubleClick", CopyCommandOnDoubleClick)
    listView.ModifyCol(1, "123") ; Set the width of the first column
    listView.ModifyCol(2, "360") ; Set the width of the first column
    
    mainGui.show("h700 w" FINAL_WIDTH)
    mainGui.OnEvent("Close", (*) => Reload())
    AddAllSetButtons()
    InsertCommandsToListView(DEFAULT_SET ".txt", DEFAULT_SET) ; Set de default set
}