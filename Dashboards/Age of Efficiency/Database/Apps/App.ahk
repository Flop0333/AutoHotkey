class CustomApp {
    __New(id := "", title := "", actionId := "", argument := "", argumentRequired := "", command := "", category := "", icon := "") {
        this.id := id
        this.title := title
        this.actionId := actionId
        this.argumentRequired := argumentRequired = true ? 1 : 0
        this.argument := argument
        this.command := command
        this.category := category
        this.icon := icon
    }
}
