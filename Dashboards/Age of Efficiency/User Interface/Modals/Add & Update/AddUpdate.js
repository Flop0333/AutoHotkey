class AddUpdateModal {

  static MODAL = document.getElementById('modal-container')

  static updateMode
  static updatingItem

  static open(inUpdateMode = false, newUpdatingItem = null) {
    this.updateMode = inUpdateMode
    this.updatingItem = newUpdatingItem
    
    // Load html into modal-container
    fetch(MODAL_HTML_PATHS[Navigationbar.getActiveTab()])
      .then(response => response.text())
      .then(html => {
        AhkDataService.clearBrowsingData()
        document.getElementById('modal-container').innerHTML = html;

        // populate category dropdown
        this.#populateCategoryDropdown(AhkDataService.getAhkCategories());
        this.#populateIconDropdown()
        this.#setupEventListenerForCreatingANewCategoryInDropdown()
        
        // Insert url from clipboard for bookmarks and search
        if (Navigationbar.getActiveTab() === TAB_OPTIONS.Bookmarks || Navigationbar.getActiveTab() === TAB_OPTIONS.Search ) {
          this.#prefillUrlAndTitleFromClipboard()
        }
        
        if (Navigationbar.getActiveTab() === TAB_OPTIONS.Apps) {
          this.#setupInputArgumentEventlistener()
        }

        if (Navigationbar.getActiveTab() === TAB_OPTIONS.Bookmarks) {
          this.#setupSecretCheckboxEventlistener()
        }
        
        // Prefill data when updating item
        if (this.updateMode) {
          this.#prefillDataFromUpdatingItem(this.updatingItem)
        }
        
        AddUpdateModal.MODAL.showModal();
        document.body.addEventListener('mousedown', this.#closeWhenClickingOutside); // Set auto close

        
      });
    }


  static submit(event) {
    console.log('Form EVENT: `n', event)
    let form = event.target.closest('form');
    let formData = {};

    Array.from(form.elements).forEach(element => { 
      formData[element.id] = element.value; 
    });

    try {
      formData.argumentRequired = document.getElementById('argumentRequired').checked === true ? 1 : 0; // Checkbox should be set with .checked (instead of .value)
    } catch {}
    formData.icon = document.getElementById('selected-icon-text').textContent;

    var isSecret = document.getElementById('isSecret') ? document.getElementById('isSecret').checked : false;
    if (isSecret) {
      formData.isSecret = true;
      formData.secretPropertyName = document.getElementById('secretPropertyName').value;
      formData.secretName = document.getElementById('secretName').value;
      formData.secretDescription = document.getElementById('secretDescription').value;
    }

    console.log('Formdata: `n', formData)
    FormHandler.submit(formData, this.updateMode, this.updatingItem)
  }

  static #setupInputArgumentEventlistener() {
    const argumentRequiredCheckbox = document.getElementById('argumentRequired');
    const argumentLabel = document.getElementById('argument');
  
    argumentRequiredCheckbox.addEventListener('change', function() {
      argumentLabel.disabled = this.checked;
    });
  }

  static #populateCategoryDropdown() {
    const dropdownElement = document.getElementById('category');
    dropdownElement.innerHTML = ''; // Clear existing options
    
    // Add default empty option
    const emptyOption = document.createElement('option');
    emptyOption.value = '';
    emptyOption.textContent = 'Select a category';
    dropdownElement.appendChild(emptyOption);

    // Add create new option
    const createOption = document.createElement('option');
    createOption.value = '+ Create New';
    createOption.textContent = '+ Create New';
    dropdownElement.appendChild(createOption);
    
    // Add categories as options
    AhkDataService.getAhkCategories().forEach(category => {
        const option = document.createElement('option');
        option.value = category;
        option.textContent = category;
        dropdownElement.appendChild(option);
    });
  }

  static #populateIconDropdown() {
    const dropdownElement = document.getElementById('icon-options');
    dropdownElement.innerHTML = ''; // Clear existing options
    
    // Get the list of PNG files from the specified folder
    const pngFiles = AhkDataService.getItemIcons();
    
    const iconsPath = ICON_PATH + 'Custom Item/';

    // Add PNG file titles as options with images
    pngFiles.forEach(file => {
        const li = document.createElement('li');
        li.dataset.iconName = file;
        
        const img = document.createElement('img');
        img.src = `${iconsPath}${file}.png`;
        img.alt = file;

        const span = document.createElement('span');
        span.textContent = file;

        li.appendChild(img);
        li.appendChild(span);

        dropdownElement.appendChild(li);
    });

    // Set up event listeners
    AddUpdateModal.#setupIconDropdownEvents();

    // Select the default icon initially
    const selectedIconImg = document.getElementById('selected-icon-img');
    const selectedIconText = document.getElementById('selected-icon-text');

    selectedIconImg.src = `${iconsPath}default.png`;
    selectedIconText.textContent = 'default';
  }

  static #setupIconDropdownEvents() {
    const dropdownElement = document.getElementById('icon-dropdown');
    const optionsList = document.getElementById('icon-options');
    const selectedIconImg = document.getElementById('selected-icon-img');
    const selectedIconText = document.getElementById('selected-icon-text');

    dropdownElement.addEventListener('click', () => {
        optionsList.classList.toggle('show');
    });

    optionsList.addEventListener('click', (event) => {
        // Check if the click was on a list item or any of its children
        let target = event.target;
        while (target && target.tagName !== 'LI') {
            target = target.parentNode;
        }

        if (target && target.tagName === 'LI') {
            const selectedOption = target;
            const iconName = selectedOption.dataset.iconName;
            
            selectedIconImg.src = `${ICON_PATH}Custom Item/${iconName}.png`;
            selectedIconText.textContent = iconName;

            // Close the dropdown
            optionsList.classList.remove('show');
            
            // Prevent the click event from bubbling up and toggling the dropdown again
            event.stopPropagation();
        }
    });
    
    // Add event listener to close dropdown when clicking outside
    document.addEventListener('click', (event) => {
      if (!event.target.closest('#icon-dropdown')) {
          optionsList.classList.remove('show');
      }
    });
  }

  static #setupEventListenerForCreatingANewCategoryInDropdown() {
    const categoryElement = document.getElementById('category');
    const customCategoryElement = document.getElementById('customCategory');

    categoryElement.addEventListener('change', () => {
      if (categoryElement.value === '+ Create New') {
          customCategoryElement.style.display = 'block';
          categoryElement.style.display = 'none';
      }
    });
  }

  static #prefillDataFromUpdatingItem(updateItem) {
    // Fill data for all navigation types
    document.getElementById('addTitle').textContent = 'Update ' + updateItem.title;
    document.getElementById('title').value = updateItem.title;
    document.getElementById('command').value = updateItem.command;
    document.getElementById('category').value = updateItem.category;
    document.getElementById('submit-button').textContent = 'Update Item';

    // Select icon
    const selectedIconImg = document.getElementById('selected-icon-img');
    const selectedIconText = document.getElementById('selected-icon-text');

    selectedIconImg.src = `${ICON_PATH}Custom Item/${updateItem.icon}.png`;
    selectedIconText.textContent = updateItem.icon;
    
    // Fill data for specific navigation type
    switch (Navigationbar.getActiveTab()) {
      case TAB_OPTIONS.Bookmarks:
        document.getElementById('url').value = updateItem.url;
        if (updateItem.isSecret) {
          document.getElementById('isSecret').checked = true;
          document.getElementById('secretFields').style.display = 'block';
          document.getElementById('secretPropertyName').value = updateItem.secretPropertyName;
          document.getElementById('secretPropertyName').disabled = true // Can't change secret property name in update mode
          document.getElementById('secretName').value = updateItem.secretName;
          document.getElementById('secretName').disabled = true; // Can't change secret name in update mode
          document.getElementById('secretDescription').value = updateItem.secretDescription;
          document.getElementById('secretDescription').disabled = true; // Can't change secret description in update mode
        }
        break;
        
      case TAB_OPTIONS.Apps:
        document.getElementById('action').value = updateItem.action;
        
        const argumentRequiredCheckbox = document.getElementById('argumentRequired');
        argumentRequiredCheckbox.checked = updateItem.argumentRequired
        
        const argumentLabel = document.getElementById('argument');
        argumentLabel.disabled = argumentRequiredCheckbox.checked;
        argumentLabel.value = updateItem.argument;
        break;

      case TAB_OPTIONS.Search:
        document.getElementById('url').value = updateItem.url;
        break;
    }
  }
        
  static #prefillUrlAndTitleFromClipboard() {
    let ahkUrlObject = AhkDataService.getUrlFromClipboard()
    document.getElementById('title').value = ahkUrlObject.title;
    document.getElementById('url').value = ahkUrlObject.url;
  }

  static #closeWhenClickingOutside(event) {
    if (!event.target.closest('#add-update-container') && !event.target.closest('#message-modal-container')) {
      AddUpdateModal.MODAL.close();
      document.body.removeEventListener('mousedown', AddUpdateModal.#closeWhenClickingOutside);
    }
  }
  
  static #setupSecretCheckboxEventlistener() {
  const isSecretCheckbox = document.getElementById('isSecret');
  const secretFields = document.getElementById('secretFields');
  isSecretCheckbox.addEventListener('change', function() {
    if (this.checked) {
      secretFields.style.display = 'block';
    } else {
      secretFields.style.display = 'none';
    }
  });
}

}