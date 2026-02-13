class MessageModal {

  static MESSAGE_MODAL = document.getElementById('message-modal-container')
  
  static open(message) {
    fetch(MODAL_HTML_PATHS.Message)
    .then(response => response.text())
    .then(html => {
      document.getElementById('message-modal-container').innerHTML = html;
      document.getElementById('message').innerHTML = message
      this.MESSAGE_MODAL.showModal();
      
      document.body.addEventListener('click', MessageModal.#closeWhenClickingOutside); // Set auto close
    })
  }
  
  static close =() => MessageModal.MESSAGE_MODAL.close();

  static #closeWhenClickingOutside(event) {
    if (!event.target.closest('#message-container')) {
      MessageModal.close();
      document.body.removeEventListener('click', MessageModal.#closeWhenClickingOutside);
    }
  }
}
