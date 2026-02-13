class Navigationbar {

  static onClick(tab) {
    // Remove 'selected' class from all buttons, add it back to current one
    const allTabs = document.querySelectorAll('.tab');
    allTabs.forEach(btn => btn.classList.remove('selected'));
    tab.classList.add('selected');
    
    Items.loadAll();
    Sidebar.loadAllCategories();
  }

  static getActiveTab() {
    const allTabs = document.querySelectorAll('.tab');
    const activeTab = Array.from(allTabs).find(button => button.classList.contains('selected'));
    return activeTab ? activeTab.textContent : null;
  }
}
