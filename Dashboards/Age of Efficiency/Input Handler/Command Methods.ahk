; ============================================================================
; === Command Methods ========================================================
; ============================================================================
;
; - Command methods executed by CommandExecutor
; - Each method corresponds to an app action defined in Apps.json
; ============================================================================

#Include Internet Searcher.ahk
#Include ..\User Interface\Controller.ahk
#Include ..\..\..\Apps Integrated\Fake Working Mode.ahk
#Include ..\..\..\Apps Integrated\Kill All Ahk Processes.ahk
#Include ..\..\..\Apps Integrated\PBI Reformat.ahk
#Include ..\..\..\Apps Integrated\Timer.ahk
#Include ..\..\..\Apps Integrated\Status Memes\Status Meme.ahk
#Include ..\..\..\Apps Integrated\Virtual Machine.ahk
#Include ..\..\..\Apps Integrated\Picture In Picture.ahk
#Include ..\..\..\Startup\Startup.ahk
#Include ..\..\..\Lib\Apps\Notion.ahk

StartPBIReformat() => PBIReformat.Start()

OpenAgeOfEfficiency() => aoeWindow.Show()

StartFakeWorkMode() => FakeWorkMode.Start()

ShutPcDown() => System.PowerDown()

RerunStartup() => RunStartup()

ShowStatusMeme(meme) => StatusMeme(meme)

OpenKeePass() => Run(A_MyDocuments "\Database.kdbx")

CapsOff() => SetCapsLockState('OFF')

StartRemoteDesktop(setting := "H3") => VirtualMachine.StartRemoteDesktop(setting)

StartTimer(time) => Timer.Start(time)