class DeleteModal {
  
  static MODAL = document.getElementById('modal-container')

  static open(item) {
    fetch(MODAL_HTML_PATHS.Delete)
    .then(response => response.text())
    .then(html => {
      document.getElementById('modal-container').innerHTML = html;
      document.getElementById('delete-item-title').textContent += item.title + '?'
      document.body.addEventListener('click', this.#closeWhenClickingOutside);
      this.MODAL.showModal();
      
      // Yes button logic
      document.querySelector('.yesBtn').addEventListener('click', function() {
        AhkDataService.deleteItem(item.title)
        DeleteModal.MODAL.close();
        Items.reloadByTab();
      });
      
      // No button logic
      document.querySelector('.noBtn').addEventListener('click', function() { 
        DeleteModal.MODAL.close() 
      });
    })
  }
  
  static #closeWhenClickingOutside(event) {
    if (!event.target.closest('#delete-item-container')) {
      DeleteModal.MODAL.close();
      document.body.removeEventListener('click', DeleteModal.#closeWhenClickingOutside);
    }
  }
}
