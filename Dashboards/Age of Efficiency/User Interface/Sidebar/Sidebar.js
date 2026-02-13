class Sidebar {

  static loadAllCategories() {
    document.getElementById('category-list').innerHTML = ''; // Clear the existing items
    this.#addSingleCategoryButton('All'); // Add 'All' button and set it as selected by default
    AhkDataService.getAhkCategories().forEach(item => this.#addSingleCategoryButton(item)); // Add other category buttons
  }

  static onClickSidebarButton(button) {
    // Remove 'selected' class from all buttons, add it back to current one
    const buttons = document.querySelectorAll('.category-button');
    buttons.forEach(btn => btn.classList.remove('selected'));
    button.classList.add('selected');

    this.#loadItemsByCategory(button.textContent)
  }

  static #addSingleCategoryButton(item) {
    const li = document.createElement('li');
    const button = document.createElement('button');
    button.className = 'category-button';
  
    const span = document.createElement('span');
    span.textContent = item;
    button.appendChild(span);
  
    if (item == 'All') {
      button.classList.add('selected');
    }
  
    button.onclick = () => this.onClickSidebarButton(button);
  
    li.appendChild(button);
    document.getElementById('category-list').appendChild(li);
  }
  

  static #loadItemsByCategory(currentCategory) {
    Items.clearAll()
    AhkDataService.getItemsByTab().forEach(ahkItem => {
      if (currentCategory === 'All' || ahkItem.category === currentCategory) {
        Items.addSingleItem(ahkItem);
      }
    });
  }
}
