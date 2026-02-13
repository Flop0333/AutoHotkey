
document.addEventListener('DOMContentLoaded', () => {
	new MyClass().render();
});

// Disable right-click context menu
document.addEventListener('contextmenu', (e) => e.preventDefault());

class MyClass {

	constructor() {
		this.ahkObjects = AhkDataService.GetAhkObjects();
		console.log('Objects from ahk backend: ', this.ahkObjects)
		this.objectsContainer = document.querySelector('.buttons-container');
	}
	
	render() {
		this.ahkObjects.forEach(object => {
			var buttonElement = document.createElement('button');
			buttonElement.className = 'my-object';
			buttonElement.title = object.tooltip;
			buttonElement.addEventListener('click', () => this._triggerAction(object));
			this.objectsContainer.appendChild(buttonElement);
		});
	}

	_triggerAction = (button) => AhkDataService.TriggerButtonFunction(button);
}

