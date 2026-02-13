class GestureConfig {
    static Hotkey := "RButton" ; Hotkey to hold while performing gestures
    static MinDistance := 9 ; Minimum px distance to consider a movement as a gesture
    static MaxGestureLength := 3 ; Max 3 directions (ex: LUR)
}

class GestureDetector {
    activeGesture := ""
    lastDirection := ""
    startX := 0
    startY := 0
    
    __New() {
        ; Set up hotkey to start gesture detection
        HotIf (*) => this.ShouldAllowGesture()
        Hotkey "$*" GestureConfig.Hotkey, (*) => this.OnMouseDown()
        HotIf
    }
    
    ShouldAllowGesture() {
        ; Override this method to add custom blocking conditions
        ; Example: if WinActive("ahk_class Notepad") return false
        return true
    }
    
    OnMouseDown() {
        this.SetStartCoordinates()
        this.activeGesture := ""
        this.lastDirection := ""
        
        this.TrackGesture()
    }

    TrackGesture() {
        Loop {
            Sleep 20
            
            if (!GetKeyState(GestureConfig.Hotkey, "p")) {
                this.OnMouseUp()
                return
            }
            
            MouseGetPos(&currentX, &currentY)
            distance := this.CalculateDistance(this.startX, this.startY, currentX, currentY)
            
            if (distance < GestureConfig.MinDistance)
                continue
            
            angle := this.CalculateAngle(this.startX, this.startY, currentX, currentY)
            direction := this.AngleToDirection(angle)
            
            this.SetStartCoordinates()
            
            if (direction != this.lastDirection) {
                this.activeGesture .= direction
                this.lastDirection := direction
                
                if (StrLen(this.activeGesture) > GestureConfig.MaxGestureLength) {
                    this.CancelGesture()
                    return
                }
            }
        }
    }
    
    OnMouseUp() {
        ; If no gesture was detected, send the original hotkey
        if (this.activeGesture = "")
            SendInput("{" GestureConfig.Hotkey "}")
        ; Execute the action associated with the detected gesture
        else
            Gestures.GetAction(this.activeGesture).Call()
    }
 
    SetStartCoordinates() {
        MouseGetPos(&x, &y)
        this.startX := x
        this.startY := y
    }
    
    CancelGesture() {
        DarkToolTip("Gesture cancelled")
        KeyWait GestureConfig.Hotkey
    }
    
    CalculateAngle(startX, startY, endX, endY) {
        x := endX - startX
        y := endY - startY
        
        if (x = 0) {
            if (y > 0)
                return 180
            else if (y < 0)
                return 360
            else
                return 0
        }
        
        angle := ATan(y/x) * 57.295779513
        return (x > 0) ? angle + 90 : angle + 270
    }
    
    CalculateDistance(startX, startY, endX, endY) {
        a := Abs(endX - startX)
        b := Abs(endY - startY)
        return Sqrt(a*a + b*b)
    }
    
    AngleToDirection(angle) {
        ; Divide circle into 4 quadrants: U(315-45), R(45-135), D(135-225), L(225-315)
        if (angle < 45 || angle >= 315)
            return "U"
        else if (angle < 135)
            return "R"
        else if (angle < 225)
            return "D"
        else
            return "L"
    }
}