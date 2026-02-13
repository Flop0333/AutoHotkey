class MyModel {
    __New(funcName, tooltip, image?) {
        this.funcName := funcName
        this.tooltip := tooltip
        this.image := IsSet(image) ? image : unset
    }
}
