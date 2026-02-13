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
    FileDelete this.STORAGE_FILE_PATH
    FileAppend JSON.stringify(JSON.ToPlainObjectArray(stateArray)), this.STORAGE_FILE_PATH
  }
}