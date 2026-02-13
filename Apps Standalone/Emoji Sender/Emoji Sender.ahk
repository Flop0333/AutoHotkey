; ============================================================================
; === Emoji Sender - Quick emoji picker GUI =================================
; ============================================================================
;
; [FEATURES]
; - Shows 4x4 grid of customizable emojis near cursor
; - Send emojis by clicking or using corresponding keyboard shortcuts
; - Auto-closes when focus is lost
; - Fully customizable emoji list and GUI size
;
; [HOTKEYS]
; - Alt + X - Open emoji picker
; - 1-4, Q-R, A-F, Z-V - Send corresponding emoji (when picker is open)
;
; [CUSTOMIZATION]
; - Edit MY_EMOJIS array to change emoji selection
; - Adjust SIZE variable to resize the entire GUI
; ============================================================================

#SingleInstance Force
#NoTrayIcon
#Include ..\..\Lib\Extensions\Dark Gui.ahk
#Include ..\..\Lib\Core\Paths.ahk
SetTitleMatchMode 3 ; Match the title exactly (for editing this script)
CoordMode "Mouse", "Screen"

!x::EmojiSender.Show()


Class EmojiSender {
    
    static MY_EMOJIS := [
        "😋", "😏", "🤓", "🤔",
        "😎", "😅", "🙈", "🍻",
        "😂", "😇", "😘", "❤",
        "💪", "👍", "🥳", "🎉",
    ]
    
    static SIZE         := 10 ; <-- Adjust this to resize the gui

    ; Varriables for auto resizing
    static BUTTON_SIZE  := 8 * this.SIZE
    static FONT_SIZE    := Ceil((28 / 10) * this.Size)
    static GUI_SIZE     := 40 * this.SIZE
    static X_STARTPOS   := Ceil((25 /10) * this.SIZE)
    static Y_STARTPOS   := Ceil((25 /10) * this.SIZE)
    static MIN_Y_POS    := 0 + (this.GUI_SIZE / 2)
    static MAX_Y_POS    := A_ScreenHeight - (this.GUI_SIZE / 2)
    static BUTTON_DISTANCE := 9 * this.SIZE
    static BACKGROUND_PICUTRE_PATH := "Background.png"

    static _emoji   := String
    static _window  := unset
    static _gui     := DarkGui

    static __New() => this._ActiveHotkeys()
    
    static Show() {
        this._window := WinGetID("A")
        try this._gui.Destroy()

        this._gui := DarkGui("-Caption +AlwaysOnTop").FontSize(this.FONT_SIZE)
        this._gui.BackColor := "0x423728"
        WinSetTransColor("0x423728", this._gui)

        this._gui.AddPicture("x0 y0 w" this.GUI_SIZE " h" this.GUI_SIZE, this.BACKGROUND_PICUTRE_PATH)
        this._AddEmojiButtons()
        this._ShowGui()
    }

    static _AddEmojiButtons() {
        y := this.Y_STARTPOS
        emojiIndex := 1

        Loop 4 { ; rows
            x := this.X_STARTPOS ; Reset x for first button
            if A_Index != 1 && A_Index != this.MY_EMOJIS.Length +1 ; Add Line Break
                y += this.BUTTON_DISTANCE ; Line break

            Loop 4 { ; colums
                try {
                    currentEmoji := this.MY_EMOJIS[emojiIndex++]
                    this._gui.AddButton(Format("x{} y{} w{} h{} ", x, y, this.BUTTON_SIZE, this.BUTTON_SIZE), currentEmoji).OnEvent("Click", this._SendEmojiHandler(currentEmoji))
                    x += this.BUTTON_DISTANCE
                } 
                catch 
                    break
            }
        }
    }
    
    static _SendEmojiHandler(emoji) => (*) => this._Send(emoji)
    
    static _Send(emoji) {
        WinActivate(this._window)
        Sleep(50)
        Send(emoji)
        try this._gui.Destroy()
    }

    static _ShowGui() {
        MouseGetPos &xpos, &ypos
        ypos := (ypos > this.MAX_Y_POS) ? this.MAX_Y_POS : ypos + Ceil((this.GUI_SIZE / 4)) ; check max pos
        ypos := (ypos < this.MIN_Y_POS) ? this.MIN_Y_POS  + Ceil((this.GUI_SIZE / 3)): ypos ; check min pos
        try this._gui.Show(Format("x{} y{}", xpos - Ceil((this.GUI_SIZE / 1.6)) , ypos - Ceil((this.GUI_SIZE / 1.17))))

        SetTimer _DestroyGuiIfNotActive, 100 
        _DestroyGuiIfNotActive() {
            if (WinGetTitle("A") != A_ScriptName) {
                try this._gui.Destroy()
                SetTimer , 0
            }
        }
    }

    static _ActiveHotkeys() {
        HotIfWinActive(A_ScriptName)
		Hotkey("1", (*) => this._Send(this.MY_EMOJIS[1]))  ; first 4 keys of numbers row
		Hotkey("2", (*) => this._Send(this.MY_EMOJIS[2]))
		Hotkey("3", (*) => this._Send(this.MY_EMOJIS[3]))
		Hotkey("4", (*) => this._Send(this.MY_EMOJIS[4]))

		Hotkey("q", (*) => this._Send(this.MY_EMOJIS[5]))  ; first 4 keys of top letters row
		Hotkey("w", (*) => this._Send(this.MY_EMOJIS[6]))
		Hotkey("e", (*) => this._Send(this.MY_EMOJIS[7]))
		Hotkey("r", (*) => this._Send(this.MY_EMOJIS[8]))

		Hotkey("a", (*) => this._Send(this.MY_EMOJIS[9]))  ; first 4 keys of middle letters row
		Hotkey("s", (*) => this._Send(this.MY_EMOJIS[10]))
		Hotkey("d", (*) => this._Send(this.MY_EMOJIS[11]))
		Hotkey("f", (*) => this._Send(this.MY_EMOJIS[12]))
        
		Hotkey("z", (*) => this._Send(this.MY_EMOJIS[13])) ; first 4 keys of bottom letters row
		Hotkey("x", (*) => this._Send(this.MY_EMOJIS[14]))
		Hotkey("c", (*) => this._Send(this.MY_EMOJIS[15]))
		Hotkey("v", (*) => this._Send(this.MY_EMOJIS[16]))
    }
}
