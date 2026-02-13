const TAB_OPTIONS = {
  Bookmarks: 'Bookmarks',
  Apps: 'Apps',
  Search: 'Search'
}

const ICON_PATH = '../Library/Icons/'

document.addEventListener('DOMContentLoaded', () => {
  // Load html files
  Promise.all([
    fetch('Navigationbar/Navigationbar.html').then(response => response.text()),
    fetch('Sidebar/Sidebar.html').then(response => response.text()),
    fetch('Items/Items.html').then(response => response.text()),
    fetch(MODAL_HTML_PATHS.Bookmarks).then(response => response.text()),
  ])
  .then(([navbarHtml, sidebarHtml, itemsHtml, modalHtml]) => {
    document.getElementById('header-container').innerHTML = navbarHtml;
    document.getElementById('sidebar-container').innerHTML = sidebarHtml;
    document.getElementById('content-container').innerHTML = itemsHtml;
    document.getElementById('modal-container').innerHTML = modalHtml;
    Items.reloadByTab()
  })
});
