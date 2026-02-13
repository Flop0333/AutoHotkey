
class FormHandler {

  updateMode 
  updatingItem

  static submit(formData, inUpdateMode, inUpdatingItem) {
    this.updateMode = inUpdateMode;
    this.updatingItem = inUpdatingItem;

    formData['category'] = formData['customCategory'] !== '' ? formData['customCategory'] : formData['category']
    formData['id'] = this.updateMode ? this.updatingItem.id : 0

    if (!(this.#validateUniqueTitle(formData['title'])) ||
        !(this.#validateUniqueCommand(formData['command']))) {
      return
    }

    AhkDataService.submitForm(JSON.stringify(formData), this.updateMode)
    AddUpdateModal.MODAL.close();
    Items.reloadByTab()
  }

  static #validateUniqueCommand(newCommand) {
    if (newCommand === '') {
      return true // command is not required
    }

    if (this.updateMode && newCommand === this.updatingItem.command) {
      console.log('no changes to command')
      return true // no changes have been made in updatemode
    }

    const matchingItem = AhkDataService.getAllItems().find(item => 
      item?.command?.toLowerCase() === newCommand.toLowerCase()
    );

    if (matchingItem) {
      MessageModal.open(`Command must be unique<br><br>Item: ${matchingItem.title}`);
      return false;
    }
    return true; // Command is unique
  }

  static #validateUniqueTitle(newTitle) {
    if (this.updateMode && newTitle === this.updatingItem.title) {
      return true // no changes have been made in updatemode
    }

    for (let item of AhkDataService.getItemsByTab()) {
      if (item.title && item.title.toLowerCase() === newTitle.toLowerCase()) {
        MessageModal.open('Title must be unique')
        return false;
      }
    }
    return true;
  }
}
