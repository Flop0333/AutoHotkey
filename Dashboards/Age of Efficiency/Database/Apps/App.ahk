class CustomApp {
    __New(id := "", title := "", action := "", argument := "", argumentRequired := "", command := "", category := "", icon := "") {
        this.id := id
        this.title := title
        this.action := action
        this.argumentRequired := argumentRequired = true ? 1 : 0
        this.argument := argument
        this.command := command
        this.category := category
        this.icon := icon
    }
}