// Remote Board interface: one page, two modes.
//  - bubble: only the toggle, filling the small round window; drag to move it
//  - board:  every action as a tile, sized to use all available space
// On window, so the controller's ExecuteScript can reach it.
window.RemoteBoardUi = {
  DRAG_THRESHOLD: 6, // px of movement before a press becomes a drag
  GAP_RATIO: 0.025,  // gap between tiles, relative to the shorter screen side

  grid: null,
  toggle: null,
  press: null,

  init() {
    this.grid = document.getElementById('grid');
    this.toggle = document.getElementById('toggle');

    AhkDataService.GetButtons().forEach((button, i) => this.grid.appendChild(this.createTile(button, i + 1)));
    this.bindToggle();

    window.addEventListener('resize', () => this.fit());
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && this.mode === 'board') AhkDataService.ToggleBoard();
    });
    document.addEventListener('contextmenu', (e) => e.preventDefault());
    this.setMode(AhkDataService.GetMode());
  },

  get mode() {
    return document.body.classList.contains('board') ? 'board' : 'bubble';
  },

  setMode(mode) {
    document.body.classList.toggle('board', mode === 'board');
    document.body.classList.toggle('bubble', mode !== 'board');
    this.fit();
  },

  createTile(button, index) {
    const tile = document.createElement('button');
    tile.type = 'button';
    tile.className = 'tile';
    tile.setAttribute('aria-label', button.label);

    if (button.image) {
      tile.classList.add('has-image');
      tile.style.backgroundImage = `url('http://icons.local/${encodeURIComponent(button.image)}')`;
    } else {
      const icon = document.createElement('span');
      icon.className = 'icon';
      icon.textContent = button.icon || '•';
      tile.appendChild(icon);
    }
    const label = document.createElement('span');
    label.className = 'label';
    label.textContent = button.label;
    tile.appendChild(label);

    tile.addEventListener('click', () => {
      AhkDataService.Trigger(index);
      tile.classList.remove('fired');
      void tile.offsetWidth; // restart the animation on repeated taps
      tile.classList.add('fired');
    });
    return tile;
  },

  // In bubble mode a press is either a tap (toggle) or a drag (move the
  // window). Windows takes over the drag, so no pointerup follows a drag.
  bindToggle() {
    const t = this.toggle;
    t.addEventListener('pointerdown', (e) => {
      if (this.mode !== 'bubble') return;
      this.press = { x: e.screenX, y: e.screenY };
      t.setPointerCapture(e.pointerId);
    });
    t.addEventListener('pointermove', (e) => {
      if (!this.press) return;
      if (Math.hypot(e.screenX - this.press.x, e.screenY - this.press.y) < this.DRAG_THRESHOLD) return;
      this.press = null;
      t.releasePointerCapture(e.pointerId);
      AhkDataService.StartDrag();
    });
    t.addEventListener('pointerup', () => {
      if (this.mode === 'bubble' && !this.press) return; // the press became a drag
      this.press = null;
      AhkDataService.ToggleBoard();
    });
    t.addEventListener('pointercancel', () => (this.press = null));
  },

  // Picks the column count that makes the tiles as large as possible (the
  // largest smallest side), then lets the tiles stretch to fill every cell.
  fit() {
    if (this.mode !== 'board') return;
    const tiles = this.grid.children.length;
    const style = getComputedStyle(this.grid);
    const width = this.grid.clientWidth - parseFloat(style.paddingLeft) - parseFloat(style.paddingRight);
    const height = this.grid.clientHeight - parseFloat(style.paddingTop) - parseFloat(style.paddingBottom);
    const gap = Math.round(Math.min(width, height) * this.GAP_RATIO);

    let best = { cols: 1, rows: tiles, size: 0 };
    for (let cols = 1; cols <= tiles; cols++) {
      const rows = Math.ceil(tiles / cols);
      const w = (width - (cols - 1) * gap) / cols;
      const h = (height - (rows - 1) * gap) / rows;
      const size = Math.min(w, h);
      if (size > best.size) best = { cols, rows, size };
    }

    this.grid.style.setProperty('--cols', best.cols);
    this.grid.style.setProperty('--rows', best.rows);
    this.grid.style.setProperty('--gap', `${gap}px`);
  },
};

document.addEventListener('DOMContentLoaded', () => RemoteBoardUi.init());
