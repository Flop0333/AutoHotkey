Class Bookmark {
  __New(id := "", title := "", url := "", category := "", command := "", icon := "", isSecret := 0) {
    this.id := id
    this.title := title
    this.url := url
    this.category := category
    this.command := command
    this.icon := icon
    this.isSecret := isSecret ; Store as boolean (0 or 1) whether this bookmark's url is a secret property name, instead of a direct URL
  }
}