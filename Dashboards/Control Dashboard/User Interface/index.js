document.addEventListener('DOMContentLoaded', () => {
	new ControlDashboardShell().start();
});

// The frame every section plugs into: rail navigation, the always-visible
// status strip, and the shared toast and confirmation surfaces. Sections own
// their own markup and refresh; the shell owns when they are shown and polled.
class ControlDashboardShell {

	// Matches the Logger's own polling cadence.
	static POLL_INTERVAL_MS = 1000;

	// Logs is the default while the other sections are placeholders - it is the
	// view the Logger popup and the error tray tip expect to land on.
	static DEFAULT_SECTION = 'logs';

	constructor() {
		this.rail = document.querySelector('#rail');
		this.toastElement = document.querySelector('#toast');
		this.statusStrip = new StatusStrip();
		this.confirmDialog = new ConfirmDialog();
		this.sections = new Map();
		this.activeSectionId = null;
	}

	start() {
		this._register(new PlaceholderSection('overview'));
		this._register(new PlaceholderSection('processes'));
		this._register(new LogsSection(this));
		this._register(new PlaceholderSection('tests'));
		this._register(new PlaceholderSection('profiles'));
		this._register(new PlaceholderSection('health'));

		this.rail.addEventListener('click', (event) => {
			const item = event.target.closest('.rail-item');
			if (item)
				this.show(item.dataset.section);
		});

		this.show(ControlDashboardShell.DEFAULT_SECTION);
		this._refreshStatus();
		this._loadGitStatus();
		setInterval(() => this._tick(), ControlDashboardShell.POLL_INTERVAL_MS);
	}

	show(sectionId) {
		if (!this.sections.has(sectionId) || sectionId === this.activeSectionId)
			return;

		for (const [id, section] of this.sections)
			section.element.hidden = id !== sectionId;
		this.rail.querySelectorAll('.rail-item').forEach(item =>
			item.classList.toggle('active', item.dataset.section === sectionId));

		this.activeSectionId = sectionId;
		this.sections.get(sectionId).activate();
	}

	showToast(message) {
		this.toastElement.textContent = message;
		this.toastElement.classList.remove('show');
		void this.toastElement.offsetWidth; // restart the animation even if a toast is already showing
		this.toastElement.classList.add('show');
	}

	// Shared by every section that acts on the suite, so a destructive action is
	// always confirmed in the page - never through a message box the dashboard
	// process would pop up behind its own window.
	confirm(options) {
		return this.confirmDialog.ask(options);
	}

	_register(section) {
		this.sections.set(section.id, section);
	}

	// Only the visible section is refreshed, so navigation, filters, and an open
	// detail panel survive every tick.
	_tick() {
		this._refreshStatus();
		const active = this.sections.get(this.activeSectionId);
		if (active)
			this._guard(() => active.refresh());
	}

	_refreshStatus() {
		this._guard(() => this.statusStrip.render(AhkDataService.GetSuiteStatus()));
	}

	async _loadGitStatus() {
		const gitStatus = document.querySelector('#git-status');
		try {
			const status = await AhkDataService.GetGitStatus();
			if (!status.branch) {
				gitStatus.textContent = '';
				return;
			}
			const ahead = Number(status.ahead) || 0;
			const behind = Number(status.behind) || 0;
			let text = status.branch;
			if (ahead) text += ` ↑${ahead}`;
			if (behind) text += ` ↓${behind}`;
			gitStatus.textContent = text;
		} catch (error) {
			gitStatus.textContent = 'git-status error: ' + error.message;
		}
	}

	// A failing bridge call must not kill the polling interval.
	_guard(work) {
		try {
			work();
		} catch (error) {
			console.error(error);
		}
	}
}

// Profile, session uptime, unread log counts, and the last test result, visible
// from every section.
class StatusStrip {

	constructor() {
		this.profile = document.querySelector('#status-profile');
		this.uptime = document.querySelector('#status-uptime');
		this.unread = document.querySelector('#status-unread');
		this.tests = document.querySelector('#status-tests');
	}

	render(status) {
		this.profile.textContent = status.profile || 'unknown';
		this.uptime.textContent = StatusStrip.FormatUptime(status.uptimeSeconds);
		this._renderUnread(status.unread || {});
		this._renderTests(status.tests || {});
	}

	static FormatUptime(seconds) {
		const total = Number(seconds);
		if (!Number.isFinite(total) || total < 0)
			return 'unknown';
		if (total < 60)
			return 'just started';
		const hours = Math.floor(total / 3600);
		const minutes = Math.floor((total % 3600) / 60);
		return hours ? `${hours}h ${minutes}m` : `${minutes}m`;
	}

	_renderUnread(unread) {
		const severities = ['error', 'warning', 'info'];
		const present = severities.filter(severity => Number(unread[severity]) > 0);
		this.unread.replaceChildren(...(present.length
			? present.map(severity => Pill(`${unread[severity]} ${severity}`, severity))
			: [Pill('none', 'neutral')]));
	}

	_renderTests(tests) {
		if (tests.status === 'running') {
			this.tests.replaceChildren(Pill('running…', 'info'));
			return;
		}
		if (!tests.lastRunStatus) {
			this.tests.replaceChildren(Pill('no runs yet', 'neutral'));
			return;
		}
		const passed = tests.lastRunStatus === 'PASS';
		this.tests.replaceChildren(Pill(passed ? 'passed' : 'failed', passed ? 'success' : 'error'));
	}
}

// The page's own confirmation, resolved as a promise so a caller reads as
// `if (await shell.confirm(...))`.
class ConfirmDialog {

	constructor() {
		this.element = document.querySelector('#confirm-modal');
		this.title = document.querySelector('#confirm-title');
		this.message = document.querySelector('#confirm-message');
		this.acceptButton = document.querySelector('#confirm-accept');
		this.cancelButton = document.querySelector('#confirm-cancel');
		this.resolve = null;

		this.acceptButton.addEventListener('click', () => this._close(true));
		this.cancelButton.addEventListener('click', () => this._close(false));
		this.element.addEventListener('click', (event) => {
			if (event.target === this.element)
				this._close(false);
		});
		document.addEventListener('keydown', (event) => {
			if (!this.element.hidden && event.key === 'Escape')
				this._close(false);
		});
	}

	ask({ title, message, confirmLabel = 'Confirm', danger = true }) {
		this.title.textContent = title;
		this.message.textContent = message;
		this.acceptButton.textContent = confirmLabel;
		this.acceptButton.classList.toggle('button-danger', danger);
		this.element.hidden = false;
		this.acceptButton.focus();
		return new Promise(resolve => this.resolve = resolve);
	}

	_close(accepted) {
		if (!this.resolve)
			return;
		this.element.hidden = true;
		const resolve = this.resolve;
		this.resolve = null;
		resolve(accepted);
	}
}

// A section whose markup is in place but whose behavior has not shipped yet.
class PlaceholderSection {

	constructor(id) {
		this.id = id;
		this.element = document.querySelector(`#section-${id}`);
	}

	activate() {}

	refresh() {}
}

// The structured log view: filter, sort, inspect, and copy entries from
// Logs\errors.log, plus the buttons that emit test notifications.
class LogsSection {

	constructor(shell) {
		this.id = 'logs';
		this.shell = shell;
		this.element = document.querySelector('#section-logs');
		this.entries = AhkDataService.GetLogEntries();
		this.sortDescending = true;
		this.selectedKey = null;
		this.tableBody = this.element.querySelector('#log-table tbody');
		this.detailPanel = this.element.querySelector('#detail-panel');
		this.severityFilter = this.element.querySelector('#severity-filter');
		this.scriptFilter = this.element.querySelector('#script-filter');
		this.sortButton = this.element.querySelector('#sort-time');
		this.entryCount = this.element.querySelector('#entry-count');
		this.openArchiveButton = this.element.querySelector('#open-archive');
		this.testButtons = this.element.querySelectorAll('.test-btn');
		this.rendered = false;
	}

	activate() {
		if (this.rendered)
			return;
		this._populateFilters();
		this._attachEvents();
		this._renderRows();
		this.rendered = true;
	}

	// Entries are plain objects re-created on every fetch, so object identity
	// can't survive a refresh - this key (good enough for a personal log, not
	// a guaranteed-unique id) is what lets a live update find the previously
	// selected row again without disturbing what the user is doing.
	_entryKey(entry) {
		return `${entry.timestamp}|${entry.script}|${entry.message}`;
	}

	// Applies new entries without resetting filters, sort, or the open detail
	// view - unlike a manual _refresh(), which is a deliberate full reset.
	refresh() {
		const fresh = AhkDataService.GetLogEntries();
		if (fresh.length === this.entries.length)
			return;

		const wasCleared = fresh.length < this.entries.length; // e.g. StartNewLogSession() at the next full-suite start
		this.entries = fresh;
		this._repopulateFiltersKeepingSelection();

		if (wasCleared) {
			this.selectedKey = null;
			this._renderEmptyDetail();
		}

		this._renderRows();

		if (this.selectedKey) {
			const row = [...this.tableBody.querySelectorAll('tr')].find(r => r.dataset.key === this.selectedKey);
			if (row)
				row.classList.add('selected');
		}
	}

	_repopulateFiltersKeepingSelection() {
		const previousSeverity = this.severityFilter.value;
		const previousScript = this.scriptFilter.value;
		this.severityFilter.innerHTML = '<option value="">All severities</option>';
		this.scriptFilter.innerHTML = '<option value="">All scripts</option>';
		this._populateFilters();
		this.severityFilter.value = previousSeverity;
		this.scriptFilter.value = previousScript;
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
		this.openArchiveButton.addEventListener('click', () => AhkDataService.OpenLogArchive());
		this.testButtons.forEach(button => {
			button.addEventListener('click', () => {
				AhkDataService.LogTestMessage(button.dataset.severity);
				this._reset();
			});
		});
	}

	_copyToClipboard(text, toastMessage) {
		AhkDataService.SetClipboard(text);
		this.shell.showToast(toastMessage);
	}

	_reset() {
		this.entries = AhkDataService.GetLogEntries();
		this._repopulateFiltersKeepingSelection();
		this.selectedKey = null;
		this._renderEmptyDetail();
		this._renderRows();
	}

	_renderEmptyDetail() {
		this.detailPanel.innerHTML = '<p class="empty-state">Select a log entry to see details.</p>';
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
				<td>${escapeHtml(entry.timestamp)}</td>
				<td class="severity severity-${escapeHtml(entry.severity)}">${escapeHtml(entry.severity)}</td>
				<td>${escapeHtml(entry.script)}</td>
				<td class="message-cell">${escapeHtml(entry.message)}</td>
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
				<h2>${escapeHtml(entry.severity.toUpperCase())}: ${escapeHtml(entry.message)}</h2>
				<button type="button" class="button copy-btn" title="Copy details to clipboard">📋 Copy</button>
			</div>
			<p><strong>Script:</strong> ${escapeHtml(entry.script)}</p>
			<p><strong>Time:</strong> ${escapeHtml(entry.timestamp)}</p>
			<pre>${escapeHtml(entry.stack || '(no stack trace)')}</pre>
		`;
		this.detailPanel.querySelector('.copy-btn').addEventListener('click', () => {
			const details = `${entry.severity.toUpperCase()}: ${entry.message}\nScript: ${entry.script}\nTime: ${entry.timestamp}\n\n${entry.stack || '(no stack trace)'}`;
			this._copyToClipboard(details, 'Error details copied to clipboard');
		});
	}
}

function Pill(text, tone = 'neutral') {
	const pill = document.createElement('span');
	pill.className = `pill pill-${tone}`;
	pill.textContent = text;
	return pill;
}

function escapeHtml(text) {
	const holder = document.createElement('div');
	holder.textContent = text ?? '';
	return holder.innerHTML;
}
