
document.addEventListener('DOMContentLoaded', () => {
	new Buttons().render();
});

// Disable right-click context menu
document.addEventListener('contextmenu', (e) => e.preventDefault());

class Buttons {

	constructor() {
		this.buttons = AhkDataService.GetButtons();
		this.buttonsContainer = document.querySelector('.buttons-container');
		console.log('buttons from ahk backend: ', this.buttons)
	}
	
	render() {
		this.buttons.forEach(button => {
			var buttonElement = document.createElement('button');
			buttonElement.className = 'macro-button';
			buttonElement.title = button.tooltip;
			buttonElement.dataset.funcName = button.funcName;
			this._setBackground(buttonElement, button);
			
			// Set initial toggle state
			if (button.isToggle) {
				buttonElement.classList.add('toggle-button');
				this._updateToggleState(buttonElement, button.state);
			}
			
			buttonElement.addEventListener('click', () => this._triggerAction(button, buttonElement));
			this.buttonsContainer.appendChild(buttonElement);
		});
	}

	async _setBackground(element, button) {
		const image = button.image;
		const imagePath = 'assets/icons/' + image;
		const defaultImagePath = 'assets/icons/pizza.gif';
		
		try {
			await fetch(imagePath, { method: 'HEAD' });
			element.style.backgroundImage = `url('${imagePath}')`;
		} catch {
			console.warn(`Button image ${image} not found for button "${button.tooltip}". using default image instead`);
			element.style.backgroundImage = `url('${defaultImagePath}')`;
		};
	}

	async _triggerAction(button, buttonElement) {
		const newState = await AhkDataService.TriggerButtonFunction(button);
		
		// Update toggle state if it's a toggle button
		if (button.isToggle && newState !== undefined) {
			this._updateToggleState(buttonElement, newState);
		}
	}

	_updateToggleState(buttonElement, state) {
		if (state) {
			buttonElement.classList.add('toggle-on');
			buttonElement.classList.remove('toggle-off');
		} else {
			buttonElement.classList.add('toggle-off');
			buttonElement.classList.remove('toggle-on');
		}
	}
}

