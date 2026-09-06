
document.addEventListener('DOMContentLoaded', () => {
	new LogDashboardView().render();
});

class LogDashboardView {

	static POLL_INTERVAL_MS = 1000; // matches Dashboards/Logger's own polling cadence

	constructor() {
		this.entries = AhkDataService.GetLogEntries();
		this.sortDescending = true;
		this.selectedKey = null;
		this.tableBody = document.querySelector('#log-table tbody');
		this.detailPanel = document.querySelector('#detail-panel');
		this.severityFilter = document.querySelector('#severity-filter');
		this.scriptFilter = document.querySelector('#script-filter');
		this.sortButton = document.querySelector('#sort-time');
		this.refreshButton = document.querySelector('#refresh-btn');
		this.refreshIcon = document.querySelector('#refresh-icon');
		this.entryCount = document.querySelector('#entry-count');
		this.toast = document.querySelector('#toast');
		this.gitStatus = document.querySelector('#git-status');
		this.testButtons = document.querySelectorAll('.test-btn');
	}

	render() {
		this._populateFilters();
		this._attachEvents();
		this._renderRows();
		this._loadGitStatus();
		setInterval(() => this._checkForUpdates(), LogDashboardView.POLL_INTERVAL_MS);
	}

	// Entries are plain objects re-created on every fetch, so object identity
	// can't survive a refresh - this key (good enough for a personal log, not
	// a guaranteed-unique id) is what lets a live update find the previously
	// selected row again without disturbing what the user is doing.
	_entryKey(entry) {
		return `${entry.timestamp}|${entry.script}|${entry.message}`;
	}

	// Polls for new entries (same cadence as Dashboards/Logger) and applies
	// them without resetting the user's filters, sort, or open detail view -
	// unlike a manual _refresh(), which is a deliberate full reset.
	_checkForUpdates() {
		const fresh = AhkDataService.GetLogEntries();
		if (fresh.length === this.entries.length)
			return;

		const wasCleared = fresh.length < this.entries.length; // e.g. ClearErrorLog() at the next full-suite start
		this.entries = fresh;

		const previousSeverity = this.severityFilter.value;
		const previousScript = this.scriptFilter.value;
		this.severityFilter.innerHTML = '<option value="">All severities</option>';
		this.scriptFilter.innerHTML = '<option value="">All scripts</option>';
		this._populateFilters();
		this.severityFilter.value = previousSeverity;
		this.scriptFilter.value = previousScript;

		if (wasCleared) {
			this.selectedKey = null;
			this.detailPanel.innerHTML = '<p class="empty-state">Select a log entry to see details.</p>';
		}

		this._renderRows();

		if (this.selectedKey) {
			const row = [...this.tableBody.querySelectorAll('tr')].find(r => r.dataset.key === this.selectedKey);
			if (row)
				row.classList.add('selected');
		}
	}

	async _loadGitStatus() {
		try {
			const status = await AhkDataService.GetGitStatus();
			if (!status.branch) {
				this.gitStatus.textContent = '';
				return;
			}
			const ahead = Number(status.ahead) || 0;
			const behind = Number(status.behind) || 0;
			let text = status.branch;
			if (ahead) text += ` ↑${ahead}`;
			if (behind) text += ` ↓${behind}`;
			this.gitStatus.textContent = text;
		} catch (e) {
			this.gitStatus.textContent = 'git-status error: ' + e.message;
		}
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
		this.refreshButton.addEventListener('click', () => {
			this.refreshIcon.classList.remove('spinning');
			void this.refreshIcon.offsetWidth; // restart the animation even if it's still running
			this.refreshIcon.classList.add('spinning');
			this._refresh();
		});
		this.testButtons.forEach(button => {
			button.addEventListener('click', () => {
				AhkDataService.LogTestMessage(button.dataset.severity);
				this._refresh();
			});
		});
	}

	_copyToClipboard(text, toastMessage) {
		AhkDataService.SetClipboard(text);
		this._showToast(toastMessage);
	}

	_showToast(message) {
		this.toast.textContent = message;
		this.toast.classList.remove('show');
		void this.toast.offsetWidth; // restart the animation even if a toast is already showing
		this.toast.classList.add('show');
	}

	_refresh() {
		const previousSeverity = this.severityFilter.value;
		const previousScript = this.scriptFilter.value;

		this.entries = AhkDataService.GetLogEntries();
		this.severityFilter.innerHTML = '<option value="">All severities</option>';
		this.scriptFilter.innerHTML = '<option value="">All scripts</option>';
		this._populateFilters();
		this.severityFilter.value = previousSeverity;
		this.scriptFilter.value = previousScript;

		this.selectedKey = null;
		this.detailPanel.innerHTML = '<p class="empty-state">Select a log entry to see details.</p>';
		this._renderRows();
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
			row.dataset.key = this._entryKey(entry);
			row.innerHTML = `
				<td>${this._escape(entry.timestamp)}</td>
				<td class="severity severity-${this._escape(entry.severity)}">${this._escape(entry.severity)}</td>
				<td>${this._escape(entry.script)}</td>
				<td class="message-cell">${this._escape(entry.message)}</td>
			`;
			row.addEventListener('click', () => this._showDetail(entry, row));
			row.querySelector('.message-cell').addEventListener('click', (e) => {
				e.stopPropagation();
				this._showDetail(entry, row);
				this._copyToClipboard(entry.message, 'Message copied to clipboard');
			});
			this.tableBody.appendChild(row);
		});
	}

	_showDetail(entry, row) {
		this.tableBody.querySelectorAll('tr').forEach(r => r.classList.remove('selected'));
		row.classList.add('selected');
		this.selectedKey = this._entryKey(entry);
		this.detailPanel.innerHTML = `
			<div class="detail-header">
				<h2>${this._escape(entry.severity.toUpperCase())}: ${this._escape(entry.message)}</h2>
				<button class="copy-btn" title="Copy details to clipboard">📋 Copy</button>
			</div>
			<p><strong>Script:</strong> ${this._escape(entry.script)}</p>
			<p><strong>Time:</strong> ${this._escape(entry.timestamp)}</p>
			<pre>${this._escape(entry.stack || '(no stack trace)')}</pre>
		`;
		this.detailPanel.querySelector('.copy-btn').addEventListener('click', () => {
			const details = `${entry.severity.toUpperCase()}: ${entry.message}\nScript: ${entry.script}\nTime: ${entry.timestamp}\n\n${entry.stack || '(no stack trace)'}`;
			this._copyToClipboard(details, 'Error details copied to clipboard');
		});
	}

	_escape(text) {
		const div = document.createElement('div');
		div.textContent = text ?? '';
		return div.innerHTML;
	}
}
