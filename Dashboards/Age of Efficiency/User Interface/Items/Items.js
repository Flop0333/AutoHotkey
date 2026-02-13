class Items {

  static loadAll() {
    this.clearAll();
    AhkDataService.getItemsByTab().forEach(this.addSingleItem);
  }
  
  static clearAll() {
    document.getElementById('items-list').innerHTML = '';
  }
  
  static reloadByTab() {
    const tab = document.querySelector('.tab.selected');
    setTimeout(() => { // Sleep a bit to make sure the json is updated before they get loaded again
      Navigationbar.onClick(tab);
    }, 100);
  }

  static openAddUpdateModal(updateMode = false, itemTitle) { 
    let itemToUpdate = AhkDataService.getItemByTitle(itemTitle)
    AddUpdateModal.open(updateMode, itemToUpdate)
  }

  static addSingleItem(item) {
    // Create li element
    const li = document.createElement('li');
    li.className = 'item-button';
    
    const div = document.createElement('div');
    div.className = 'item-content';
    div.onclick = () => AhkDataService.clickItem(item);
    
    // Create custom item img
    const itemImg = document.createElement('img');
    itemImg.className = 'custom-item-icon';
    if (item.icon === null || item.icon === '') {
      itemImg.src = ICON_PATH + 'Custom Item/default.png';
    } else {
      itemImg.src = ICON_PATH + 'Custom Item/' + item.icon + '.png';
    }
    div.appendChild(itemImg);

    // Create title 
    const titleH3 = document.createElement('h3');
    titleH3.className = 'item-title';
    titleH3.textContent = item.title;
    
    // Create command
    const commandP = document.createElement('p');
    commandP.className = 'item-command';
    commandP.textContent = item.command;
    
    // Create edit img
    const editImg = document.createElement('img');
    editImg.className = 'edit-icon';
    editImg.src = 'Library/Theme/edit item.png' // ICON_PATH + 'edit.png';
    editImg.onclick = function(event) {
      event.stopPropagation();
      Items.openAddUpdateModal(true, item.title);
    };
    
    // Create delete img
    const deleteImg = document.createElement('img');
    deleteImg.className = 'delete-icon';
    deleteImg.src = 'Library/Theme/delete item.png' // ICON_PATH + 'delete.png';
    deleteImg.onclick = function(event) {
      event.stopPropagation();
      DeleteModal.open(item)
    };
    
    // Append all elements
    li.appendChild(div);
    div.appendChild(titleH3);
    if (item.command !== "") {
      div.appendChild(commandP);
    }
    li.appendChild(editImg);
    li.appendChild(deleteImg);
    document.getElementById('items-list').appendChild(li);
  }

}
