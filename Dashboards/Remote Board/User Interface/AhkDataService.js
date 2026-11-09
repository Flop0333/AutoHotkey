// Bridge to the AutoHotkey controller (Dashboards/Remote Board/Controller.ahk).
// Falls back to sample data when opened in a normal browser, for styling.
class AhkDataService {
  static get isHosted() {
    return typeof ahk !== 'undefined';
  }

  static GetButtons() {
    if (!this.isHosted) return AhkDataService.sampleButtons;
    return JSON.parse(ahk.sync.GetButtons());
  }

  static GetMode() {
    return this.isHosted ? ahk.sync.GetMode() : 'board';
  }

  static Trigger(index) {
    if (this.isHosted) ahk.Trigger(index);
  }

  static ToggleBoard() {
    if (this.isHosted) ahk.ToggleBoard();
    else RemoteBoardUi.setMode(document.body.classList.contains('board') ? 'bubble' : 'board');
  }

  static StartDrag() {
    if (this.isHosted) ahk.StartDrag();
  }

  static sampleButtons = [
    { label: 'Tv aan', icon: '📺' },
    { label: 'Tv uit', icon: '🌙' },
    { label: 'Woonkamer', icon: '🔥' },
    { label: 'Good Morning Jazz', icon: '🎷' },
    { label: 'YouTube', icon: '▶️' },
    { label: 'Play / pauze', icon: '⏯️' },
  ];
}
