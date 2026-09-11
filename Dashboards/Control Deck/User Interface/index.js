document.addEventListener('DOMContentLoaded', () => {
	window.controlDeckShell = new ControlDeckShell();
	window.controlDeckShell.start();
});

// The frame every section plugs into: rail navigation, the always-visible
// status strip, and the shared toast and confirmation surfaces. Sections own
// their own markup and refresh; the shell owns when they are shown and polled.
class ControlDeckShell {

	// Matches the Logger's own polling cadence.
	static POLL_INTERVAL_MS = 1000;

	// Callers name the section they want - the Logger opens Logs, Run-Tests
	// opens Tests. Overview is what opening the dashboard on its own shows.
	static DEFAULT_SECTION = 'overview';

	constructor() {
		this.rail = document.querySelector('#rail');
		this.toastElement = document.querySelector('#toast');
		this.statusStrip = new StatusStrip(this);
		this.confirmDialog = new ConfirmDialog();
		this.sections = new Map();
		this.activeSectionId = null;
		// The last suite status read, for a section that activates between ticks.
		this.lastStatus = {};
	}

	start() {
		this._register(new OverviewSection(this));
		this._register(new ProcessesSection(this));
		this._register(new LogsSection(this));
		this._register(new TestsSection(this));
		this._register(new ProfilesSection(this));
		this._register(new HealthSection(this));

		this.rail.addEventListener('click', (event) => {
			const item = event.target.closest('.rail-item');
			if (item)
				this.show(item.dataset.section);
		});

		this._attachSectionLinks();
		this.show(this._requestedSection());
		this._attachKeyboardShortcuts();
		this._refreshStatus();
		this.refreshGitStatus();
		setInterval(() => this._tick(), ControlDeckShell.POLL_INTERVAL_MS);
		// The dashboard runs hidden from startup; showing it catches up at once
		// instead of waiting for the next tick.
		document.addEventListener('visibilitychange', () => {
			if (!document.hidden)
				this._tick();
		});
	}

	// Any status readout marked with data-open-section - in the strip or on a
	// card - opens the section that explains it. A control inside one, such as
	// Run tests, handles its own click and stops it from reaching here.
	_attachSectionLinks() {
		const target = event => event.target.closest('[data-open-section]');
		document.addEventListener('click', event => {
			const link = target(event);
			if (link)
				this.show(link.dataset.openSection);
		});
		document.addEventListener('keydown', event => {
			const link = target(event);
			if (link && event.target === link && (event.key === 'Enter' || event.key === ' ')) {
				event.preventDefault();
				this.show(link.dataset.openSection);
			}
		});
	}

	_attachKeyboardShortcuts() {
		document.addEventListener('keydown', (event) => {
			// A confirmation owns the keyboard while it waits for an answer:
			// switching section behind it would leave the question stranded.
			// Escape still reaches the dialog, which listens for it itself.
			if (this.confirmDialog.isOpen) return;
			const typing = event.target.matches('input, select, textarea, [contenteditable="true"]');
			if (typing) return;
			// The keys follow the rail, so reordering the rail reorders them too.
			const sections = [...this.rail.querySelectorAll('.rail-item')].map(item => item.dataset.section);
			if (/^[1-6]$/.test(event.key)) this.show(sections[Number(event.key) - 1]);
			else if (event.key.toLowerCase() === 'r') {
				this.show('tests');
				this.sections.get('tests')._run();
			} else if (event.key === '/') {
				event.preventDefault();
				this.show('logs');
				document.querySelector('#script-filter').focus();
			} else if (event.key === 'Escape' && this.activeSectionId === 'logs') {
				this.sections.get('logs')._renderEmptyDetail();
			}
		});
	}

	// A caller can ask for a section before this page exists, so the host holds
	// the request until now.
	_requestedSection() {
		let requested = '';
		this._guard(() => requested = AhkDataService.GetPendingSection());
		return this.sections.has(requested) ? requested : ControlDeckShell.DEFAULT_SECTION;
	}

	show(sectionId) {
		if (!this.sections.has(sectionId) || sectionId === this.activeSectionId)
			return;

		for (const [id, section] of this.sections)
			section.element.hidden = id !== sectionId;
		this.rail.querySelectorAll('.rail-item').forEach(item => {
			const active = item.dataset.section === sectionId;
			item.classList.toggle('active', active);
			if (active)
				item.setAttribute('aria-current', 'page');
			else
				item.removeAttribute('aria-current');
		});

		this.activeSectionId = sectionId;
		document.body.dataset.section = sectionId;
		this.sections.get(sectionId).activate();
	}

	openRepositoryInVsCode() {
		return this._inVsCode(AhkDataService.OpenRepositoryInVsCode, 'Opening the repository in VS Code…');
	}

	// Shared by the Secrets cards on the Overview and Health.
	openSecretsInVsCode() {
		return this._inVsCode(AhkDataService.OpenSecretsInVsCode, 'Opening My Secrets.json in VS Code…');
	}

	// Starting VS Code can take a moment, so the host answers asynchronously
	// instead of freezing the page while it waits.
	async _inVsCode(open, startedMessage) {
		try {
			const result = await open();
			this.showToast(result.ok ? startedMessage : `Could not open VS Code: ${result.error}`);
		} catch (error) {
			this.showToast(`Could not open VS Code: ${error.message}`);
		}
	}

	// A section requested by another script. The window stays loaded while
	// hidden, so the section asked for may already be the current one; it is
	// activated again all the same - a Logger notification reopening Logs
	// expects its entries to be marked read.
	open(sectionId) {
		if (sectionId === this.activeSectionId)
			this.sections.get(sectionId).activate();
		else
			this.show(sectionId);
	}

	showToast(message) {
		this.toastElement.textContent = message;
		this.toastElement.dataset.tone = /could not|error|failed/i.test(message)
			? 'error'
			: /warning|missing/i.test(message) ? 'warning' : 'info';
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

	// Shared by the Tests section and every "Run tests" button. A started run
	// refreshes at once so the strip shows it without waiting for the tick.
	runTests() {
		const result = AhkDataService.RunAllTests();
		this.showToast(result.ok ? 'Test run started' : `Could not start the tests: ${result.error}`);
		if (result.ok)
			this._tick();
		return result.ok;
	}

	_register(section) {
		this.sections.set(section.id, section);
	}

	// Only the visible section is refreshed, so navigation, filters, and an open
	// detail panel survive every tick. Nothing is read while the window is
	// hidden.
	_tick() {
		if (document.hidden)
			return;
		this._guard(() => {
			// One read per tick, shared by the strip and the visible section.
			const status = this.lastStatus = AhkDataService.GetSuiteStatus();
			this.statusStrip.render(status);
			const active = this.sections.get(this.activeSectionId);
			if (active)
				active.refresh(status);
		});
	}

	_refreshStatus() {
		this._guard(() => this.statusStrip.render(this.lastStatus = AhkDataService.GetSuiteStatus()));
	}

	// Reading git status starts a process, so it is loaded on demand rather than
	// polled: once at startup, and again whenever a section asks for it.
	async refreshGitStatus() {
		const gitStatus = document.querySelector('#git-status');
		try {
			this.git = await AhkDataService.GetGitStatus();
			gitStatus.textContent = ControlDeckShell.FormatGitStatus(this.git);
		} catch (error) {
			this.git = { error: error.message };
			gitStatus.textContent = 'git-status error: ' + error.message;
		}
		return this.git;
	}

	static FormatGitStatus(status) {
		if (!status || !status.branch)
			return '';
		const ahead = Number(status.ahead) || 0;
		const behind = Number(status.behind) || 0;
		let text = status.branch;
		if (ahead) text += ` ↑${ahead}`;
		if (behind) text += ` ↓${behind}`;
		return text;
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

// Processor use, profile, running scripts and session uptime, this session's
// log counts, and the last test result, visible from every section.
class StatusStrip {

	constructor(shell) {
		this.shell = shell;
		this.cpu = document.querySelector('#status-cpu');
		this.profile = document.querySelector('#status-profile');
		this.uptime = document.querySelector('#status-uptime');
		this.logs = document.querySelector('#status-logs');
		this.tests = document.querySelector('#status-tests');
	}

	render(status) {
		this._renderCpu(status.cpu || {});
		this.profile.textContent = status.profile || 'unknown';
		this.uptime.textContent = `${Number(status.runningScripts) || 0} Scripts - ${StatusStrip.FormatUptime(status.uptimeSeconds)}`;
		this.logs.replaceChildren(...LogCountPills(status.logCounts || {}, 'none', HEADER_LOG_SEVERITIES));
		RenderTestState(this.tests, status.tests || {}, () => this.shell.runTests());
	}

	_renderCpu(cpu) {
		const percent = CpuPercent(cpu);
		this.cpu.textContent = percent === null ? 'CPU …' : `CPU ${percent.toFixed(1)}%`;
		this.cpu.classList.toggle('is-busy', percent !== null && percent >= HealthSection.BUSY_PERCENT);
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
		this.previouslyFocused = null;

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

	get isOpen() {
		return !this.element.hidden;
	}

	ask({ title, message, confirmLabel = 'Confirm', danger = true }) {
		this.title.textContent = title;
		this.message.textContent = message;
		this.acceptButton.textContent = confirmLabel;
		this.acceptButton.classList.toggle('button-danger', danger);
		this.acceptButton.dataset.icon = 'confirm';
		this.element.hidden = false;
		this.previouslyFocused = document.activeElement;
		this.acceptButton.focus();
		return new Promise(resolve => this.resolve = resolve);
	}

	_close(accepted) {
		if (!this.resolve)
			return;
		this.element.hidden = true;
		const resolve = this.resolve;
		this.resolve = null;
		if (this.previouslyFocused instanceof HTMLElement)
			this.previouslyFocused.focus();
		this.previouslyFocused = null;
		resolve(accepted);
	}
}

// Suite state at a glance, plus the actions worth one click. Every action
// confirms in the page when it is destructive, and reports its outcome.
class OverviewSection {

	constructor(shell) {
		this.id = 'overview';
		this.shell = shell;
		this.element = document.querySelector('#section-overview');
		this.profile = this.element.querySelector('#overview-profile');
		this.secrets = this.element.querySelector('#overview-secrets');
		this.secretsNote = this.element.querySelector('#overview-secrets-note');
		this.logs = this.element.querySelector('#overview-logs');
		this.entries = this.element.querySelector('#overview-entries');
		this.tests = this.element.querySelector('#overview-tests');
		this.testsNote = this.element.querySelector('#overview-tests-note');
		this.wired = false;
	}

	activate() {
		if (!this.wired) {
			this._attachEvents();
			this.wired = true;
		}
		// The branch lives in the title bar; a visit here keeps it current.
		this.shell.refreshGitStatus();
		// Reading the secrets file on every tick would be wasted work for a value
		// that changes only when the file is edited, so it is read per visit.
		RenderSecrets(this.secrets, this.secretsNote, AhkDataService.GetSecretsState());
	}

	refresh(status) {
		this.profile.textContent = status.profile || 'unknown';
		const entryCount = Number(status.entryCount) || 0;
		const unreadCount = SeverityTotal(status.unread || {});
		this.entries.textContent = `${Count(entryCount, 'entry', 'entries')} this session`
			+ (unreadCount ? `, ${unreadCount} unread` : '');
		this.logs.replaceChildren(...LogCountPills(status.logCounts || {}, 'none'));
		this._renderTests(status.tests || {});
	}

	_renderTests(tests) {
		const state = RenderTestState(this.tests, tests, () => this.shell.runTests());
		if (state === 'running')
			this.testsNote.textContent = '';
		else if (state === 'idle')
			this.testsNote.textContent = 'Nothing has run since the suite started.';
		else
			this.testsNote.textContent = tests.lastRunAt ? `Finished ${tests.lastRunAt.replace('T', ' ').slice(0, 19)}` : '';
	}

	_attachEvents() {
		this.element.querySelector('#action-reload').addEventListener('click', () => this._reload());
		this.element.querySelector('#action-exit').addEventListener('click', () => this._exit());
		this.element.querySelector('#action-open-vscode')
			.addEventListener('click', () => this.shell.openRepositoryInVsCode());
		OnActivate(this.element.querySelector('#overview-secrets-card'), () => this.shell.openSecretsInVsCode());
	}

	async _reload() {
		const confirmed = await this.shell.confirm({
			title: 'Reload the suite?',
			message: 'Every AutoHotkey script is closed and started again, this dashboard included. It restarts in the background with the rest of the suite.',
			confirmLabel: 'Reload'
		});
		if (!confirmed)
			return;
		this.shell.showToast('Reloading the suite…');
		AhkDataService.ReloadSuite();
	}

	async _exit() {
		const confirmed = await this.shell.confirm({
			title: 'Exit the suite?',
			message: 'Every AutoHotkey script is closed, this dashboard included. Nothing comes back until you start the suite again from Startup.ahk.',
			confirmLabel: 'Exit'
		});
		if (!confirmed)
			return;
		this.shell.showToast('Closing the suite…');
		AhkDataService.ExitSuite();
	}
}

// The structured log view: filter, sort, inspect, and copy entries from
// Logs\errors.log, plus the buttons that emit test notifications.
class LogsSection {

	// The direction a column sorts in when it is first clicked: newest and most
	// severe first, text columns A to Z.
	static DEFAULT_DESCENDING = { timestamp: true, severity: true, script: false, message: false };

	static SEVERITY_RANK = { info: 1, warning: 2, error: 3 };

	constructor(shell) {
		this.id = 'logs';
		this.shell = shell;
		this.element = document.querySelector('#section-logs');
		this.entries = [];
		this.sortKey = 'timestamp';
		this.sortDescending = true;
		this.selectedKey = null;
		this.tableBody = this.element.querySelector('#log-table tbody');
		this.tableHead = this.element.querySelector('#log-table thead');
		this.detailPanel = this.element.querySelector('#detail-panel');
		this.severityFilter = this.element.querySelector('#severity-filter');
		this.scriptFilter = this.element.querySelector('#script-filter');
		this.entryCount = this.element.querySelector('#entry-count');
		this.openArchiveButton = this.element.querySelector('#open-archive');
		this.testButtons = this.element.querySelectorAll('.test-btn');
		this.rendered = false;
	}

	activate() {
		AhkDataService.MarkLogsRead();
		this.shell._refreshStatus();
		if (!this.rendered) {
			this.entries = AhkDataService.GetLogEntries();
			this._populateFilters();
			this._attachEvents();
			this._renderRows();
			this.rendered = true;
		}
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
	refresh(status) {
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
		this._reselectRow();
	}

	// A redraw rebuilds every row, so the selection is found again by its key.
	_reselectRow() {
		if (!this.selectedKey)
			return;
		const row = [...this.tableBody.querySelectorAll('tr')].find(r => r.dataset.key === this.selectedKey);
		if (row) {
			row.classList.add('selected');
			row.setAttribute('aria-selected', 'true');
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
		this.tableHead.addEventListener('click', (event) => {
			const header = event.target.closest('th[data-sort]');
			if (header)
				this._sortBy(header.dataset.sort);
		});
		this._renderSortIndicators();
		this.openArchiveButton.addEventListener('click', () => {
			const result = AhkDataService.OpenLogArchive();
			if (!result.ok)
				this.shell.showToast(`Could not open the archive folder: ${result.error}`);
		});
		this.testButtons.forEach(button => {
			button.addEventListener('click', () => {
				const result = AhkDataService.LogTestMessage(button.dataset.severity);
				if (!result.ok)
					this.shell.showToast(`Could not log the test entry: ${result.error}`);
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

	// Clicking the sorted column flips its direction; clicking another column
	// sorts by it in that column's natural direction.
	_sortBy(key) {
		if (key === this.sortKey)
			this.sortDescending = !this.sortDescending;
		else {
			this.sortKey = key;
			this.sortDescending = LogsSection.DEFAULT_DESCENDING[key] ?? false;
		}
		this._renderSortIndicators();
		this._renderRows();
		this._reselectRow();
	}

	_renderSortIndicators() {
		this.tableHead.querySelectorAll('th[data-sort]').forEach(header => {
			if (header.dataset.sort === this.sortKey)
				header.setAttribute('aria-sort', this.sortDescending ? 'descending' : 'ascending');
			else
				header.removeAttribute('aria-sort');
		});
	}

	static CompareBy(key, a, b) {
		if (key === 'severity')
			return (LogsSection.SEVERITY_RANK[a.severity] || 0) - (LogsSection.SEVERITY_RANK[b.severity] || 0);
		if (key === 'timestamp')
			return String(a.timestamp ?? '').localeCompare(String(b.timestamp ?? ''));
		return String(a[key] ?? '').localeCompare(String(b[key] ?? ''), undefined, { sensitivity: 'base', numeric: true });
	}

	_filteredEntries() {
		const direction = this.sortDescending ? -1 : 1;
		return this.entries
			.filter(e => !this.severityFilter.value || e.severity === this.severityFilter.value)
			.filter(e => !this.scriptFilter.value || e.script === this.scriptFilter.value)
			// Ties within a column read newest first, whatever the column's direction.
			.sort((a, b) => direction * LogsSection.CompareBy(this.sortKey, a, b)
				|| LogsSection.CompareBy('timestamp', b, a));
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
			row.tabIndex = 0;
			row.setAttribute('aria-selected', 'false');
			row.innerHTML = `
				<td>${escapeHtml(entry.timestamp)}</td>
				<td class="severity severity-${escapeHtml(entry.severity)}">${escapeHtml(entry.severity)}</td>
				<td>${escapeHtml(entry.script)}</td>
				<td class="message-cell">${escapeHtml(entry.message)}</td>
			`;
			row.addEventListener('click', () => this._showDetail(entry, row));
			row.addEventListener('keydown', event => {
				if (event.key === 'Enter' || event.key === ' ') {
					event.preventDefault();
					this._showDetail(entry, row);
				}
			});
			row.querySelector('.message-cell').addEventListener('click', (e) => {
				e.stopPropagation();
				this._showDetail(entry, row);
				this._copyToClipboard(entry.message, 'Message copied to clipboard');
			});
			this.tableBody.appendChild(row);
		});
	}

	_showDetail(entry, row) {
		this.tableBody.querySelectorAll('tr').forEach(r => {
			r.classList.remove('selected');
			r.setAttribute('aria-selected', 'false');
		});
		row.classList.add('selected');
		row.setAttribute('aria-selected', 'true');
		this.selectedKey = this._entryKey(entry);
		this.detailPanel.innerHTML = `
			<div class="detail-header">
				<h2>${escapeHtml(entry.severity.toUpperCase())}: ${escapeHtml(entry.message)}</h2>
				<button type="button" class="button copy-btn" data-icon="copy" title="Copy details to clipboard">Copy</button>
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

// Running the suites and reading what happened. Runs are scoped to the current
// suite session, matching the status strip: what ran before the suite started
// is not this session's result.
class TestsSection {

	constructor(shell) {
		this.id = 'tests';
		this.shell = shell;
		this.element = document.querySelector('#section-tests');
		this.runButton = this.element.querySelector('#action-run-suites');
		this.status = this.element.querySelector('#tests-status');
		this.statusNote = this.element.querySelector('#tests-status-note');
		this.tableBody = this.element.querySelector('#test-run-table tbody');
		this.detail = this.element.querySelector('#test-detail');
		this.runs = [];
		this.selectedTimestamp = null;
		this.wasRunning = false;
		this.wired = false;
	}

	activate() {
		if (!this.wired) {
			this.runButton.addEventListener('click', () => this._run());
			this.wired = true;
		}
		this.refresh();
	}

	refresh() {
		const state = AhkDataService.GetTestRuns();
		const running = state.status && state.status.status === 'running';

		this._renderStatus(state.status || {}, running);
		this.runButton.disabled = running;
		const lastRunStatus = state.status && state.status.lastRunStatus;
		this.runButton.dataset.testState = running
			? 'running'
			: !lastRunStatus ? 'run' : lastRunStatus === 'PASS' ? 'passed' : 'failed';
		this.runButton.setAttribute('aria-label', running ? 'Tests are running' : 'Run all tests');

		const changed = TestsSection.Fingerprint(this.runs) !== TestsSection.Fingerprint(state.runs || []);
		this.runs = state.runs || [];
		if (changed)
			this._renderRows();

		// A run that just finished is the one worth reading.
		if (this.wasRunning && !running)
			this._selectLatestRun();
		this.wasRunning = running;
	}

	static Fingerprint(runs) {
		return runs.map(run => run.timestamp).join(',');
	}

	_renderStatus(status, running) {
		if (running) {
			this.status.replaceChildren(Pill('running…', 'running'));
			this.statusNote.textContent = status.currentSuite ? `Currently: ${status.currentSuite}` : '';
			return;
		}
		if (!status.lastRunStatus) {
			this.status.replaceChildren(Pill('not run yet', 'neutral'));
			this.statusNote.textContent = 'Nothing has run since the suite started.';
			return;
		}
		const passed = status.lastRunStatus === 'PASS';
		this.status.replaceChildren(Pill(passed ? 'passed' : 'failed', passed ? 'success' : 'error'));
		this.statusNote.textContent = status.lastRunDurationSeconds
			? `Last run took ${TestsSection.FormatDuration(status.lastRunDurationSeconds)}`
			: '';
	}

	static FormatDuration(seconds) {
		const total = Number(seconds);
		if (!Number.isFinite(total))
			return '';
		if (total < 60)
			return `${total.toFixed(1)}s`;
		return `${Math.floor(total / 60)}m ${Math.round(total % 60)}s`;
	}

	static FormatTime(timestamp) {
		const time = new Date(timestamp);
		return isNaN(time) ? timestamp : time.toLocaleTimeString();
	}

	// Oldest first, so a session reads top to bottom in the order it happened.
	_renderRows() {
		this.tableBody.innerHTML = '';
		if (!this.runs.length) {
			this.tableBody.innerHTML = '<tr><td colspan="3" class="empty-state">No runs since the suite started.</td></tr>';
			return;
		}

		this.runs.forEach(run => {
			const row = document.createElement('tr');
			row.dataset.timestamp = run.timestamp;
			row.tabIndex = 0;
			row.setAttribute('aria-selected', 'false');
			const passed = run.overallStatus === 'PASS';
			row.innerHTML = `
				<td>${escapeHtml(TestsSection.FormatTime(run.timestamp))}</td>
				<td class="severity severity-${passed ? 'success' : 'error'}">${escapeHtml(run.overallStatus)}</td>
				<td>${escapeHtml(TestsSection.FormatDuration(run.durationSeconds))}</td>
			`;
			row.addEventListener('click', () => this._showDetail(run));
			row.addEventListener('keydown', event => {
				if (event.key === 'Enter' || event.key === ' ') {
					event.preventDefault();
					this._showDetail(run);
				}
			});
			if (run.timestamp === this.selectedTimestamp) {
				row.classList.add('selected');
				row.setAttribute('aria-selected', 'true');
			}
			this.tableBody.appendChild(row);
		});
	}

	_selectLatestRun() {
		const latest = this.runs[this.runs.length - 1];
		if (latest)
			this._showDetail(latest);
	}

	_showDetail(run) {
		this.selectedTimestamp = run.timestamp;
		this.tableBody.querySelectorAll('tr').forEach(row => {
			const selected = row.dataset.timestamp === run.timestamp;
			row.classList.toggle('selected', selected);
			row.setAttribute('aria-selected', String(selected));
		});

		this.detail.replaceChildren();
		const heading = document.createElement('h2');
		heading.className = 'modal-title';
		heading.textContent = `${TestsSection.FormatTime(run.timestamp)} · ${TestsSection.FormatDuration(run.durationSeconds)}`;
		this.detail.appendChild(heading);

		(run.suites || []).forEach(suite => this.detail.appendChild(this._suite(suite)));
	}

	_suite(suite) {
		const passed = suite.status === 'PASS';
		const element = document.createElement('div');
		element.className = 'suite';

		const name = document.createElement('span');
		name.className = 'suite-name';
		name.textContent = suite.name;
		const result = Pill(passed ? 'Passed' : 'Failed', passed ? 'success' : 'error');
		result.classList.add('suite-result');
		element.append(result, name);

		const duration = document.createElement('span');
		duration.className = 'muted-text';
		duration.textContent = TestsSection.FormatDuration(suite.durationSeconds);
		element.appendChild(duration);

		if (!passed && suite.output) {
			const copy = document.createElement('button');
			copy.type = 'button';
			copy.className = 'button';
			copy.dataset.icon = 'copy';
			copy.textContent = 'Copy output';
			copy.addEventListener('click', () => {
				AhkDataService.SetClipboard(`${suite.name}\n\n${suite.output}`);
				this.shell.showToast(`${suite.name} output copied to clipboard`);
			});
			element.appendChild(copy);

			const output = document.createElement('pre');
			output.className = 'suite-output';
			output.textContent = suite.output;
			element.appendChild(output);
		}
		return element;
	}

	// The shell's run refreshes the visible section, which is this one.
	_run() {
		this.shell.runTests();
	}
}

// Which profile is active, which machine names map to each one, and switching
// into another - which needs a suite restart to take effect.
class ProfilesSection {

	constructor(shell) {
		this.id = 'profiles';
		this.shell = shell;
		this.element = document.querySelector('#section-profiles');
		this.origin = this.element.querySelector('#profile-origin');
		this.list = this.element.querySelector('#profile-list');
	}

	activate() {
		this.refresh();
	}

	// Profiles only change across a restart, so this reads once per visit
	// rather than on every tick.
	refresh() {
		if (this.list.childElementCount)
			return;
		this._render(AhkDataService.GetProfiles());
	}

	_render(state) {
		this.origin.textContent = state.origin === 'detected'
			? `This computer is ${state.computerName}, which matches the ${state.current} profile.`
			: `This computer is ${state.computerName}. The ${state.current} profile was chosen by hand; it does not match this machine's name.`;

		// The active profile leads; the rest keep the order Profile Manager gives.
		const profiles = [...(state.profiles || [])]
			.sort((a, b) => (Number(b.isCurrent) || 0) - (Number(a.isCurrent) || 0));
		this.list.replaceChildren(...profiles.map(profile => this._card(profile)));
	}

	_card(profile) {
		const card = document.createElement('div');
		card.className = 'card stat';
		card.classList.toggle('is-active', profile.isCurrent);
		card.innerHTML = `
			<span class="stat-label">Profile</span>
			<span class="stat-value stat-value-compact">${escapeHtml(profile.displayName)}</span>
			<span class="stat-note">${profile.devices.length
				? escapeHtml(profile.devices.join(', '))
				: 'no device names; never auto-detected'}</span>
		`;

		const actions = document.createElement('div');
		actions.className = 'action-row profile-actions';
		if (profile.isCurrent) {
			actions.appendChild(Pill('active', 'success'));
		} else {
			const button = document.createElement('button');
			button.type = 'button';
			button.className = 'button';
			button.dataset.icon = 'switch-profile';
			button.textContent = 'Switch and reload';
			button.addEventListener('click', () => this._switch(profile));
			actions.appendChild(button);
		}
		card.appendChild(actions);
		return card;
	}

	async _switch(profile) {
		const confirmed = await this.shell.confirm({
			title: `Switch to ${profile.displayName}?`,
			message: 'The suite restarts into that profile, this dashboard included. Anything the current profile started is closed first.',
			confirmLabel: 'Switch and reload'
		});
		if (!confirmed)
			return;

		const result = AhkDataService.RequestProfile(profile.displayName);
		if (!result.ok) {
			this.shell.showToast(`Could not switch profile: ${result.error}`);
			return;
		}
		this.shell.showToast(`Reloading into ${profile.displayName}…`);
		AhkDataService.ReloadSuite();
	}
}

// The AutoHotkey processes that make up the running suite, with restart and
// stop per script. Rows are keyed by process id so a refresh can redraw
// without losing the scroll position or what the user is reading.
class ProcessesSection {

	constructor(shell) {
		this.id = 'processes';
		this.shell = shell;
		this.element = document.querySelector('#section-processes');
		this.tableBody = this.element.querySelector('#process-table tbody');
		this.tableWrap = this.element.querySelector('.table-wrap');
		this.processes = [];
		this.loading = false;
		this.hasLoaded = false;
	}

	activate() {
		if (!this.hasLoaded)
			this._renderLoading();
		requestAnimationFrame(() => this.refresh());
	}

	async refresh() {
		if (this.loading)
			return;
		this.loading = true;
		this.element.setAttribute('aria-busy', 'true');
		try {
			const processes = await AhkDataService.GetProcesses();
			const changed = !this.hasLoaded || ProcessesSection.Fingerprint(this.processes) !== ProcessesSection.Fingerprint(processes);
			this.processes = processes;
			this.hasLoaded = true;
			// Uptime ticks every second; redrawing the table for that alone would
			// fight the user's scrolling, so only a changed set of processes
			// redraws and the uptime cells are updated in place.
			if (changed)
				this._renderRows();
			else
				this._updateUptimes();
		} catch (error) {
			this.tableBody.innerHTML = `<tr><td colspan="4" class="empty-state empty-state-error">Could not load processes: ${escapeHtml(error.message)}</td></tr>`;
		} finally {
			this.loading = false;
			this.element.removeAttribute('aria-busy');
		}
	}

	_renderLoading() {
		this.tableBody.innerHTML = '<tr><td colspan="4" class="loading-state" role="status">Scanning running scripts…</td></tr>';
	}

	static Fingerprint(processes) {
		return processes.map(process => `${process.processId}:${process.path}:${process.isMissing || 0}`).sort().join(',');
	}

	_updateUptimes() {
		for (const process of this.processes) {
			// A missing script has no uptime; its cell keeps saying so.
			if (process.isMissing)
				continue;
			const row = this.tableBody.querySelector(`tr[data-process-id="${process.processId}"]`);
			if (row)
				row.children[2].textContent = StatusStrip.FormatUptime(process.uptimeSeconds);
		}
	}

	_renderRows() {
		const scrollTop = this.tableWrap.scrollTop;
		this.tableBody.innerHTML = '';

		if (!this.processes.length) {
			this.tableBody.innerHTML = '<tr><td colspan="4" class="empty-state">No AutoHotkey processes are running.</td></tr>';
			return;
		}

		// The suite's own scripts first; anything running from elsewhere is
		// context, not something this dashboard manages, so it sinks below.
		this.processes
			.slice()
			.sort((a, b) => (Number(b.belongsToSuite) || 0) - (Number(a.belongsToSuite) || 0)
				|| a.name.localeCompare(b.name))
			.forEach(process => this.tableBody.appendChild(this._row(process)));
		this.tableWrap.scrollTop = scrollTop;
	}

	_row(process) {
		const row = document.createElement('tr');
		row.dataset.processId = process.processId;
		row.classList.toggle('process-missing', !!process.isMissing);
		row.innerHTML = `
			<td>
				<span class="script-name">${escapeHtml(process.name)}</span>
				<span class="script-path" title="${escapeHtml(process.path)}">${escapeHtml(process.path)}</span>
			</td>
			<td>${process.isMissing ? '—' : escapeHtml(process.processId)}</td>
			<td>${process.isMissing ? 'missing' : escapeHtml(StatusStrip.FormatUptime(process.uptimeSeconds))}</td>
			<td class="row-actions"></td>
		`;

		if (!process.belongsToSuite)
			row.querySelector('.script-name').appendChild(Pill('outside the repository', 'neutral'));
		if (process.isDashboard)
			row.querySelector('.script-name').appendChild(Pill('this dashboard', 'info'));
		if (process.isMissing)
			row.querySelector('.script-name').appendChild(Pill('expected · missing', 'warning'));

		const actions = row.querySelector('.row-actions');
		if (process.isMissing) {
			actions.appendChild(this._actionButton('Start', () => this._start(process)));
			return row;
		}
		actions.appendChild(this._actionButton('Restart', () => this._restart(process)));
		if (!process.isDashboard)
			actions.appendChild(this._actionButton('Stop', () => this._stop(process), true));
		return row;
	}

	_start(process) {
		const result = AhkDataService.StartExpectedScript(process.name);
		this.shell.showToast(result.ok ? `${process.name} started` : `Could not start ${process.name}: ${result.error}`);
		this._forceRedrawOnNextRefresh();
	}

	_actionButton(label, onClick, danger = false) {
		const button = document.createElement('button');
		button.type = 'button';
		button.className = danger ? 'button button-danger' : 'button';
		button.dataset.icon = label.toLowerCase();
		button.textContent = label;
		button.addEventListener('click', onClick);
		return button;
	}

	_restart(process) {
		const result = AhkDataService.RestartScript(process.processId);
		this.shell.showToast(result.ok
			? `${process.name} restarted`
			: `Could not restart ${process.name}: ${result.error}`);
		this._forceRedrawOnNextRefresh();
	}

	async _stop(process) {
		const confirmed = await this.shell.confirm({
			title: `Stop ${process.name}?`,
			message: process.isLoggingHost
				? 'This is the Logger host: stopping it leaves the suite unable to show notifications until the next reload.'
				: 'The script stops until you restart it or reload the suite. Nothing else is affected.',
			confirmLabel: 'Stop'
		});
		if (!confirmed)
			return;

		const result = AhkDataService.StopScript(process.processId);
		this.shell.showToast(result.ok
			? `${process.name} stopped`
			: `Could not stop ${process.name}: ${result.error}`);
		this._forceRedrawOnNextRefresh();
	}

	// A restarted script keeps its name but changes process id, so the next
	// refresh must compare against something that cannot match.
	_forceRedrawOnNextRefresh() {
		this.hasLoaded = false;
	}
}

// Whether this machine is set up the way the suite expects, and what the
// suite is costing it. The setup is read once per visit - it changes only
// across a restart or a hand edit - while processor use follows every tick.
class HealthSection {

	// Above this share of the machine, something is spinning rather than
	// waiting - worth flagging without calling it an error.
	static BUSY_PERCENT = 25;

	constructor(shell) {
		this.id = 'health';
		this.shell = shell;
		this.element = document.querySelector('#section-health');
		this.cpu = this.element.querySelector('#health-cpu');
		this.cpuNote = this.element.querySelector('#health-cpu-note');
		this.ahkVersion = this.element.querySelector('#health-ahk-version');
		this.ahkPath = this.element.querySelector('#health-ahk-path');
		this.webView = this.element.querySelector('#health-webview');
		this.webViewNote = this.element.querySelector('#health-webview-note');
		this.secrets = this.element.querySelector('#health-secrets');
		this.secretsNote = this.element.querySelector('#health-secrets-note');
		this.session = this.element.querySelector('#health-session');
		this.sessionNote = this.element.querySelector('#health-session-note');
		this.repository = this.element.querySelector('#health-repository');
		this.logDirectory = this.element.querySelector('#health-log-directory');
		this.wired = false;
	}

	activate() {
		if (!this.wired) {
			this._attachEvents();
			this.wired = true;
		}
		this._render(AhkDataService.GetHealth());
		this.refresh(this.shell.lastStatus);
	}

	// Processor use comes with the suite status, sampled once per tick for the
	// strip and this section alike.
	refresh(status) {
		this._renderCpu(status.cpu || {});
	}

	_render(health) {
		const autoHotkey = health.autoHotkey || {};
		this.ahkVersion.textContent = autoHotkey.version ? `v${autoHotkey.version}` : 'unknown';
		this.ahkPath.textContent = autoHotkey.path || '';

		const webView2 = health.webView2 || {};
		const known = webView2.status === 'ok';
		this.webView.replaceChildren(Pill(known ? 'installed' : 'version unknown', known ? 'success' : 'warning'));
		this.webViewNote.textContent = known
			? webView2.version
			: 'This window is rendered by WebView2, so it is installed; its version could not be read.';

		RenderSecrets(this.secrets, this.secretsNote, health.secrets || {});

		const session = health.session || {};
		this.session.textContent = session.id || 'unknown';
		this.sessionNote.textContent = `${Count(Number(session.archivedSessions) || 0, 'archived session', 'archived sessions')}`;

		const paths = health.paths || {};
		this.repository.textContent = paths.repository || 'unknown';
		this.logDirectory.textContent = paths.logDirectoryOverride
			? `Logs redirected to ${paths.logs} by AUTOHOTKEY_LOG_DIR`
			: `Logs in ${paths.logs}`;
	}

	// Reported the way Task Manager reports it: a share of the whole machine,
	// summed over every AutoHotkey process.
	_renderCpu(cpu) {
		const processes = Number(cpu.processes) || 0;
		const cores = Number(cpu.processorCount) || 0;
		const percent = CpuPercent(cpu);
		if (percent === null) {
			this.cpu.replaceChildren(Pill('sampling…', 'running'));
			this.cpuNote.textContent = `Measuring ${Count(processes, 'process', 'processes')} over the next second.`;
			return;
		}
		const busy = percent >= HealthSection.BUSY_PERCENT;
		this.cpu.replaceChildren(Pill(`${percent.toFixed(1)}%`, busy ? 'warning' : 'success'));
		this.cpuNote.textContent = `${Count(processes, 'process', 'processes')} across ${Count(cores, 'core', 'cores')}`
			+ (busy ? ' - something is working hard' : '');
	}

	_attachEvents() {
		const open = (work, name) => {
			const result = work();
			if (!result.ok)
				this.shell.showToast(`Could not open the ${name}: ${result.error}`);
		};
		this.element.querySelector('#action-open-logs')
			.addEventListener('click', () => open(AhkDataService.OpenLogFolder, 'logs folder'));
		this.element.querySelector('#action-open-archive')
			.addEventListener('click', () => open(AhkDataService.OpenLogArchive, 'archive folder'));
		this.element.querySelector('#action-open-repository')
			.addEventListener('click', () => open(AhkDataService.OpenRepository, 'repository'));
		// The cards act on what they describe, like the Overview's Secrets card.
		OnActivate(this.element.querySelector('#health-secrets-card'), () => this.shell.openSecretsInVsCode());
		OnActivate(this.element.querySelector('#health-repository-card'), () => open(AhkDataService.OpenRepository, 'repository'));
	}
}

// Shared by Overview and Health, so both describe the secrets file the same way.
function RenderSecrets(valueElement, noteElement, secrets) {
	const catalogKeys = Number(secrets.catalogKeys) || 0;
	const keysWithValue = Number(secrets.keysWithValue) || 0;
	const tones = { ok: 'success', partial: 'neutral', missing: 'warning', invalid: 'error' };
	const labels = {
		ok: 'complete',
		partial: 'partly filled in',
		missing: 'no local file',
		invalid: 'unreadable'
	};
	const state = secrets.status || 'missing';
	valueElement.replaceChildren(Pill(labels[state] || state, tones[state] || 'neutral'));
	noteElement.textContent = state === 'missing'
		? 'Start the suite once to create the local secrets file.'
		: `${keysWithValue} of ${catalogKeys} catalog keys have a value on this machine.`;
}

// The first sample only sets a baseline, so there is no percentage yet.
function CpuPercent(cpu) {
	if (cpu.percent === '' || cpu.percent === undefined || cpu.percent === null)
		return null;
	const percent = Number(cpu.percent);
	return Number.isFinite(percent) ? percent : null;
}

// "Not run yet" is an invitation rather than a result, so it is shown as the
// button that starts a run. The element is redrawn only when the state
// changes, so the button keeps its hover and focus across the one-second poll.
function RenderTestState(element, tests, onRun) {
	const state = tests.status === 'running' ? 'running'
		: !tests.lastRunStatus ? 'idle'
		: tests.lastRunStatus === 'PASS' ? 'passed' : 'failed';
	if (element.dataset.state === state)
		return state;
	element.dataset.state = state;

	if (state === 'idle') {
		const button = document.createElement('button');
		button.type = 'button';
		button.className = 'pill pill-neutral pill-action';
		button.textContent = 'Run tests';
		button.title = 'Run all tests';
		button.addEventListener('click', event => {
			// The readout around this button opens Tests; starting a run should not.
			event.stopPropagation();
			// Held until the run shows up, so a second click cannot start another;
			// released again if the runner never reports in.
			button.disabled = true;
			if (onRun())
				setTimeout(() => button.disabled = false, 10000);
			else
				button.disabled = false;
		});
		element.replaceChildren(button);
	} else if (state === 'running') {
		element.replaceChildren(Pill('running…', 'running'));
	} else {
		const passed = state === 'passed';
		element.replaceChildren(Pill(passed ? 'passed' : 'failed', passed ? 'success' : 'error'));
	}
	return state;
}

const LOG_SEVERITIES = ['error', 'warning', 'info'];
const HEADER_LOG_SEVERITIES = ['info', 'warning', 'error'];

// One pill per severity that has entries, most severe first unless an order is given.
function LogCountPills(counts, emptyLabel, order = LOG_SEVERITIES) {
	const present = order.filter(severity => Number(counts[severity]) > 0);
	return present.length
		? present.map(severity => Pill(`${counts[severity]} ${severity}`, severity))
		: [Pill(emptyLabel, 'neutral')];
}

function SeverityTotal(counts) {
	return LOG_SEVERITIES.reduce((total, severity) => total + (Number(counts[severity]) || 0), 0);
}

// A card that acts rather than navigates: click, Enter, and Space all run it.
function OnActivate(element, handler) {
	element.addEventListener('click', handler);
	element.addEventListener('keydown', event => {
		if (event.key === 'Enter' || event.key === ' ') {
			event.preventDefault();
			handler();
		}
	});
}

function Count(amount, singular, plural) {
	return `${amount} ${amount === 1 ? singular : plural}`;
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
