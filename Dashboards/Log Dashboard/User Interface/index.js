
document.addEventListener('DOMContentLoaded', () => {
	new LogDashboardView().render();
});

class LogDashboardView {

	constructor() {
		this.entries = AhkDataService.GetLogEntries();
		this.sortDescending = true;
		this.tableBody = document.querySelector('#log-table tbody');
		this.detailPanel = document.querySelector('#detail-panel');
		this.severityFilter = document.querySelector('#severity-filter');
		this.scriptFilter = document.querySelector('#script-filter');
		this.sortButton = document.querySelector('#sort-time');
		this.entryCount = document.querySelector('#entry-count');
	}

	render() {
		this._populateFilters();
		this._attachEvents();
		this._renderRows();
	}

	_populateFilters() {
		const severities = [...new Set(this.entries.map(e => e.severity))].sort();
		const scripts = [...new Set(this.entries.map(e => e.script))].sort();
		severities.forEach(s => this.severityFilter.appendChild(new Option(s, s)));
		scripts.forEach(s => this.scriptFilter.appendChild(new Option(s, s)));
	}

	_attachEvents() {
		this.severityFilter.addEventListener('change', () => this._renderRows());
		this.scriptFilter.addEventListener('change', () => this._renderRows());
		this.sortButton.addEventListener('click', () => {
			this.sortDescending = !this.sortDescending;
			this.sortButton.textContent = `Time ${this.sortDescending ? '↓' : '↑'}`;
			this._renderRows();
		});
	}

	_filteredEntries() {
		return this.entries
			.filter(e => !this.severityFilter.value || e.severity === this.severityFilter.value)
			.filter(e => !this.scriptFilter.value || e.script === this.scriptFilter.value)
			.sort((a, b) => this.sortDescending
				? b.timestamp.localeCompare(a.timestamp)
				: a.timestamp.localeCompare(b.timestamp));
	}

	_renderRows() {
		const rows = this._filteredEntries();
		this.entryCount.textContent = `${rows.length} of ${this.entries.length} entries`;
		this.tableBody.innerHTML = '';

		if (!rows.length) {
			this.tableBody.innerHTML = '<tr><td colspan="4" class="empty-state">No log entries yet.</td></tr>';
			return;
		}

		rows.forEach(entry => {
			const row = document.createElement('tr');
			row.innerHTML = `
				<td>${this._escape(entry.timestamp)}</td>
				<td class="severity severity-${this._escape(entry.severity)}">${this._escape(entry.severity)}</td>
				<td>${this._escape(entry.script)}</td>
				<td class="message-cell">${this._escape(entry.message)}</td>
			`;
			row.addEventListener('click', () => this._showDetail(entry, row));
			this.tableBody.appendChild(row);
		});
	}

	_showDetail(entry, row) {
		this.tableBody.querySelectorAll('tr').forEach(r => r.classList.remove('selected'));
		row.classList.add('selected');
		this.detailPanel.innerHTML = `
			<h2>${this._escape(entry.severity.toUpperCase())}: ${this._escape(entry.message)}</h2>
			<p><strong>Script:</strong> ${this._escape(entry.script)}</p>
			<p><strong>Time:</strong> ${this._escape(entry.timestamp)}</p>
			<pre>${this._escape(entry.stack || '(no stack trace)')}</pre>
		`;
	}

	_escape(text) {
		const div = document.createElement('div');
		div.textContent = text ?? '';
		return div.innerHTML;
	}
}
