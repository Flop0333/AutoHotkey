; Base class for database services
; Handles loading and storing items to/from JSON files

Class BaseDatabaseService {

  STORAGE_FILE_PATH := "" ; Override in subclass

  GetItems(class) {
    jsonItems := JSON.parse(FileRead(this.STORAGE_FILE_PATH))
    items := []
    highestId := 0

    for index, jsonItemMap in jsonItems {
        ; create new instance of the class and set its properties
        newItem := class()
        for key, value in jsonItemMap
            newItem.%key% := value
        
        ; add to items array
        items.Push(newItem) 

        ; track highest id
        if newItem.id > highestId
            highestId := newItem.id
    }
    return {items: items, highestId: highestId}
  }

  StoreItems(stateArray) {
    ; Write to a temp file first and rename over the destination, so a crash mid-write
    ; can never leave the storage file deleted or half-written.
    content := JSON.stringify(JSON.ToPlainObjectArray(stateArray))
    tempPath := this.STORAGE_FILE_PATH . "." . A_TickCount . ".tmp"
    try FileDelete(tempPath)
    FileAppend(content, tempPath)
    FileMove(tempPath, this.STORAGE_FILE_PATH, true)
  }
}