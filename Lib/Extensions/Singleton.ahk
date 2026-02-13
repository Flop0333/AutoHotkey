class Singleton {

  static _instance := 0

  __New() {
    if IsObject(Singleton._instance) 
        return Singleton._instance

    Singleton._instance := this
  }
}