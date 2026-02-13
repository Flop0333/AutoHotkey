#Include ..\..\..\IniService.ahk

class SettingsService extends IniService {

    __New(settingStoragePath) {
        super.__New(settingStoragePath "\settings.ini")
    }

    ReconstructIniFile() {
        this.CreateSection("Window")
            .AddKeyValue("Window", "width", "100")
            .AddKeyValue("Window", "height", "100")
            .AddKeyValue("Window", "x", "100")
            .AddKeyValue("Window", "y", "100")
            .SaveFile()
    }
}


; /*  E X A M P L E S

    ; ; Create instance with test data
    ; testIni := SettingsService()
    ; testIni.CreateSection("TestSection").AddKeyValue("TestSection", "testKey", "420")

    ; ; Get & Set
    ; MsgBox("Data is red from in store memory. Use Save() to store it")
    ; MsgBox("Inital value: " testIni.TestSection.testKey) ; Get
    ; testIni.TestSection.testKey := Random(1,42069) ; Set
    ; MsgBox("New set value: " testIni.TestSection.testKey) ; Get
    
    ; ; Create Section
    ; testIni.CreateSection("NewSection1")
    ; MsgBox("Created New section: NewSection1") ; found after creation

    ; ; Add Key & Value
    ; testIni.AddKeyValue("NewSection1", "testKey", "testValue")
    ; MsgBox("Added key and value to NewSection1: " testIni.NewSection1.testKey) ; found after creation
    
    ; testIni.CreateSection("NewSection2").AddKeyValue("NewSection2", "testKey1", "testValue1").AddKeyValue("NewSection2", "testKey2", "testValue2")
    ; MsgBox("Created NewSection2 and added key and values: " testIni.NewSection2.testKey1 " & " testIni.NewSection2.testKey2) ; found after creation
    
    ; testIni.SaveFile()