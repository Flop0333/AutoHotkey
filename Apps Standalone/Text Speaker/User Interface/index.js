document.addEventListener('contextmenu', (e) => e.preventDefault());

class TextSpeakerUI {

  constructor() {
    this.ledEl = document.getElementById('led');
    this.statusTextEl = document.getElementById('status-text');
    this.playPauseBtn = document.getElementById('play-pause-btn');
    this.restartBtn = document.getElementById('restart-btn');
    this.volumeSlider = document.getElementById('volume-slider');
    this.volumeValueEl = document.getElementById('volume-value');
    this.speedValueEl = document.getElementById('speed-value');
    this.speedButtonsEl = document.getElementById('speed-buttons');

    this.speedButtons = [];
    this.draggingVolume = false;
  }

  init() {
    const state = AhkDataService.GetState();
    this._buildSpeedButtons(state.speedOptions);
    this.render(state);

    this.playPauseBtn.addEventListener('click', () => AhkDataService.TogglePlay());
    this.restartBtn.addEventListener('click', () => AhkDataService.Restart());

    this.volumeSlider.addEventListener('input', () => {
      this.draggingVolume = true;
      this.volumeValueEl.textContent = this.volumeSlider.value;
    });
    this.volumeSlider.addEventListener('change', () => {
      AhkDataService.SetVolume(Number(this.volumeSlider.value));
      this.draggingVolume = false;
    });
  }

  _buildSpeedButtons(speedOptions) {
    speedOptions.forEach((option, index) => {
      const btn = document.createElement('button');
      btn.className = 'btn speed-btn';
      btn.textContent = option.label;
      btn.addEventListener('click', () => AhkDataService.SetSpeedIndex(index));
      this.speedButtonsEl.appendChild(btn);
      this.speedButtons.push(btn);
    });
  }

  render(state) {
    this.ledEl.className = 'led led-' + state.state;
    this.statusTextEl.textContent = state.state === 'speaking' ? 'Speaking'
      : state.state === 'paused' ? 'Paused'
      : 'Idle';

    this.playPauseBtn.textContent = state.state === 'paused' ? '▶' : '⏸';

    if (!this.draggingVolume) {
      this.volumeSlider.value = state.volume;
      this.volumeValueEl.textContent = state.volume;
    }

    this.speedValueEl.textContent = state.speedLabel;
    this.speedButtons.forEach((btn, index) => {
      btn.classList.toggle('active', index === state.speedIndex);
    });
  }
}

const ui = new TextSpeakerUI();
document.addEventListener('DOMContentLoaded', () => ui.init());
window.onAhkState = (state) => ui.render(state);
