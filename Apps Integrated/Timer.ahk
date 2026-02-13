#SingleInstance Force
#Include ..\Lib\Tools\Info.ahk
#Include ..\Lib\Helpers\ClipSend.ahk
#Include ..\Lib\Extensions\Dark Gui.ahk
#Include ..\Lib\Core\Paths.ahk

LaunchTimer() => Timer.Startup()

class Timer extends DarkGui {

	static minutes := 0
	static previousTasks := ""

	static Startup(inputMinutes := 20) {
		Try timerGui.Destroy()
		SetupTasksGui()
		Timer.minutes := inputMinutes
		if WinExist("My Clock") {
			currentTime := 1
			sleep 100
		}
	}
	
	static Start(time := this.minutes) {
		this.minutes := time
		Try timerGui.Destroy()
		if WinExist("My Clock") {
			currentTime := 1
			sleep 1100
		}
		; try finishedGui.Destroy()
		Try timeChoiceGui.Destroy()
		global currentTime := this.minutes * 60
		global timerGui := DarkGui("+AlwaysOnTop -Caption", "My Clock").FontSize(30)
		myText := timerGui.AddText("x10 y10 w200", Timer.FormatMyTime(currentTime))
		timerGui.Show("x" (A_ScreenWidth // 2) - 86 " y-12 w86 h45")
		myText.SetFont("s18")
		timerGui.OnEvent("Size", Gui_Move)
		timerGui.OnEvent("Close", Gui_Close)
		SetTimer(update, 1000)
		
		update() {
			currentTime--
			Try { 
				myText.Text := Timer.FormatMyTime(currentTime)
			} catch {
				SetTimer , 0
				try tasksInfo.Destroy()
			}

			if currentTime = 0 {
				SetTimer , 0
				Timer.NewTimerGUi()
			}
		}
		Gui_Move(*) {
			timerGui.Show("x0 y-12 w130 h60")
			myText.SetFont("s30")
		}
		Gui_Close(*) {
			currentTime := 1
			; sleep 1000
			try finishedGui.Destroy()
			Timer.NewTimerGUi()
		}
	}
	
	static NewTimerGUi() {
		try SetTimer , 0
		sleep 1000
		try finishedGui.Destroy()
		timerGui.Destroy()
		try tasksInfo.Destroy()
		global finishedGui := DarkGui("-Caption", "New Timer?").FontSize(30)
		finishedGui.AddText("x55", "Time is up!")
		finishedGui.AddButton("x40", "New timer?").OnEvent("Click", TimerChoiseGui)
		finishedGui.SetFont("s10")
		timeCounter := finishedGui.AddText("x295 y190", "00:00")
		finishedGui.Show("w340 h215")
		finishedGui.OnEvent("Close", (*) => ExitApp)

		SetTimer update, 1000
		
		counter := 1
		update() {
			try timeCounter.Text := Timer.FormatMyTime(counter)
			counter++
			if counter = 3600 
				ExitApp
		}

		TimerChoiseGui(*) {
			SetTimer update, 0
			finishedGui.Destroy()
			global timeChoiceGui := DarkGui("-Caption +AlwaysOnTop", "New Timer").FontSize(30)
			start5m := (*) => Timer.Startup(5)
			start10m := (*) => Timer.Startup(10)
			start20m := (*) => Timer.Startup(20)
			start25m := (*) => Timer.Startup(25)
			start30m := (*) => Timer.Startup(30)
			start40m := (*) => Timer.Startup(40)
			start50m := (*) => Timer.Startup(50)
			start60m := (*) => Timer.Startup(60)
			timeChoiceGui.AddButton("x30 y30", " 5m").OnEvent("Click", start5m)
			timeChoiceGui.AddButton("x150 y30", "10m").OnEvent("Click", start10m)
			timeChoiceGui.AddButton("x270 y30", "20m").OnEvent("Click", start20m)
			timeChoiceGui.AddButton("x390 y30", "25m").OnEvent("Click", start25m)
			timeChoiceGui.AddButton("x30 y130", "30m").OnEvent("Click", start30m)
			timeChoiceGui.AddButton("x150 y130", "40m").OnEvent("Click", start40m)
			timeChoiceGui.AddButton("x270 y130", "50m").OnEvent("Click", start50m)
			timeChoiceGui.AddButton("x390 y130", "60m").OnEvent("Click", start60m)
			timeChoiceGui.OnEvent("Close", (*) => ExitApp)
			timeChoiceGui.Show()
		}
	}
	
	static FormatMyTime(totalSeconds) { ; To HH:MM:SS
		hours := totalSeconds // 3600
		minutes := Mod(totalSeconds // 60, 60)
		seconds := Mod(totalSeconds, 60)

		formattedTime := Format("{:02}:{:02}:{:02}", hours, minutes, seconds)
		if hours <= 0
			formattedTime := Format("{:02}:{:02}", minutes, seconds)
		return formattedTime
	}
}


/**
 * Add tasks in an info 
 */

HotIfWinActive "Add Tasks"
Hotkey "Esc", (*) => timerGui.Hide()
Hotkey "F1", (*) => ShowInfo() Timer.Start()
HotIfWinActive

SetupTasksGui() {
	global Setup_Tasks := []
	;{===Setup Tasks==================================================================
	Try timeChoiceGui.Destroy()
	global timerGui := DarkGui("-Caption", "Add Tasks").MakeFontNicer()
	
	timerGui.AddText("x59 y30", "Start Timer")

	timerGui.SetFont("s15 italic cC5C5C5")
	timerGui.AddText("x25", "Time:")
	timerGui.SetFont("s15 cblack")
	minutesAmount := timerGui.AddEdit("x25 y130 w50 r1 number")
	minutesAmount.Value := 20
	timerGui.SetFont("s15 italic cC5C5C5")
	timerGui.AddText("x85 y130", "min")
	timerGui.AddButton("x130 y130 h30 w30", "+").OnEvent("Click", (*) => minutesAmount.Value += 5)
	timerGui.AddButton("x170 y130 h30 w30", "-").OnEvent("Click", (*) => minutesAmount.Value -= 5)
	
	timerGui.AddText("x25", "Add tasks")
	timerGui.SetFont("s15 cblack")
	
	global finalTasksEdit := timerGui.AddEdit("x25 w280 r4")
	finalTasksEdit.Focus()
	
	timerGui.SetFont("norm s20")
	timerGui.AddButton("x110 y350", "Start").OnEvent("Click", (*) => ShowInfo() Timer.Start(minutesAmount.Value))
	timerGui.Show("w330 h470")
	WinSetRegion("0-0 w410 h550 r20-20", timerGui)
}

ShowInfo() {
	if finalTasksEdit.Text = ""
		return
	Timer.previousTasks := finalTasksEdit.Text
    global tasksInfo := Info(finalTasksEdit.Text)

    lines := StrSplit(finalTasksEdit.Text, "`r`n") 
    maxChars := 0 
    ; Loop through each line
    for index, line in lines {
        lineLength := StrLen(line) ; Get the length of the line
        if (lineLength > maxChars) {
            maxChars := lineLength ; Update the maximum number of characters
        }
    }

    tasksInfo._Show() ; Show it in the left corner of the main screen
}
