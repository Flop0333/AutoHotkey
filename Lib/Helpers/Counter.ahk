#Include ..\Tools\Info.ahk

class Counter {
	static num := 0

	static Increment() => (++this.num, this)
	static Decrement() => (--this.num, this)
	static Reset() => (this.num := 0, this)
	static Send() => (Send(this.num), this)
	static Show(time?) => this.ShowNumber(this.num, time?)
	static ShowNumber(numToShow, time?) {
		static currInfo := Info(numToShow, time?)
		currInfo := currInfo.ReplaceText(numToShow, time?)
	}
}