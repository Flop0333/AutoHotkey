document.addEventListener('DOMContentLoaded', () => {
	window.controlDashboardShell = new ControlDashboardShell();
	window.controlDashboardShell.start();
});

// The frame every section plugs into: rail navigation, the always-visible
// status strip, and the shared toast and confirmation surfaces. Sections own
// their own markup and refresh; the shell owns when they are shown and polled.
class ControlDashboardShell {

	// Matches the Logger's own polling cadence.
	static POLL_INTERVAL_MS = 1000;

	// Callers name the section they want - the Logger opens Logs, Run-Tests
	// opens Tests. Overview is what opening the dashboard on its own shows.
	static DEFAULT_SECTION = 'overview';

	constructor() {
		this.rail = document.querySelector('#rail');
		this.toastElement = document.querySelector('#toast');
		this.statusStrip = new StatusStrip();
		this.confirmDialog = new ConfirmDialog();
		this.sections = new Map();
		this.activeSectionId = null;
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

		this.show(this._requestedSection());
		this._attachKeyboardShortcuts();
		this._refreshStatus();
		this.refreshGitStatus();
		setInterval(() => this._tick(), ControlDashboardShell.POLL_INTERVAL_MS);
	}

	_attachKeyboardShortcuts() {
		document.addEventListener('keydown', (event) => {
			// A confirmation owns the keyboard while it waits for an answer:
			// switching section behind it would leave the question stranded.
			// Escape still reaches the dialog, which listens for it itself.
			if (this.confirmDialog.isOpen) return;
			const typing = event.target.matches('input, select, textarea, [contenteditable="true"]');
			if (typing) return;
			const sections = ['overview', 'processes', 'logs', 'tests', 'profiles', 'health'];
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
		return this.sections.has(requested) ? requested : ControlDashboardShell.DEFAULT_SECTION;
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
		this._guard(() => {
			// One read per tick, shared by the strip and the visible section.
			const status = AhkDataService.GetSuiteStatus();
			this.statusStrip.render(status);
			const active = this.sections.get(this.activeSectionId);
			if (active)
				active.refresh(status);
		});
	}

	_refreshStatus() {
		this._guard(() => this.statusStrip.render(AhkDataService.GetSuiteStatus()));
	}

	// Reading git status starts a process, so it is loaded on demand rather than
	// polled: once at startup, and again whenever a section asks for it.
	async refreshGitStatus() {
		const gitStatus = document.querySelector('#git-status');
		try {
			this.git = await AhkDataService.GetGitStatus();
			gitStatus.textContent = ControlDashboardShell.FormatGitStatus(this.git);
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
			this.tests.replaceChildren(Pill('not run yet', 'neutral'));
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

	get isOpen() {
		return !this.element.hidden;
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

	refresh(status) {}
}

// Suite state at a glance, plus the actions worth one click. Every action
// confirms in the page when it is destructive, and reports its outcome.
class OverviewSection {

	constructor(shell) {
		this.id = 'overview';
		this.shell = shell;
		this.element = document.querySelector('#section-overview');
		this.profile = this.element.querySelector('#overview-profile');
		this.uptime = this.element.querySelector('#overview-uptime');
		this.scripts = this.element.querySelector('#overview-scripts');
		this.unread = this.element.querySelector('#overview-unread');
		this.entries = this.element.querySelector('#overview-entries');
		this.tests = this.element.querySelector('#overview-tests');
		this.testsNote = this.element.querySelector('#overview-tests-note');
		this.branch = this.element.querySelector('#overview-branch');
		this.branchNote = this.element.querySelector('#overview-branch-note');
		this.wired = false;
	}

	activate() {
		if (!this.wired) {
			this._attachEvents();
			this.wired = true;
		}
		this.shell.refreshGitStatus().then(git => this._renderGit(git));
	}

	refresh(status) {
		this.profile.textContent = status.profile || 'unknown';
		this.uptime.textContent = StatusStrip.FormatUptime(status.uptimeSeconds);
		this.scripts.textContent = Number(status.runningScripts) || 0;
		this.entries.textContent = `${Number(status.entryCount) || 0} entries this session`;
		this._renderUnread(status.unread || {});
		this._renderTests(status.tests || {});
	}

	_renderUnread(unread) {
		const severities = ['error', 'warning', 'info'];
		const present = severities.filter(severity => Number(unread[severity]) > 0);
		this.unread.replaceChildren(...(present.length
			? present.map(severity => Pill(`${unread[severity]} ${severity}`, severity))
			: [Pill('all read', 'neutral')]));
	}

	_renderTests(tests) {
		if (tests.status === 'running') {
			this.tests.replaceChildren(Pill('running…', 'info'));
			this.testsNote.textContent = '';
			return;
		}
		if (!tests.lastRunStatus) {
			this.tests.replaceChildren(Pill('not run yet', 'neutral'));
			this.testsNote.textContent = 'Nothing has run since the suite started.';
			return;
		}
		const passed = tests.lastRunStatus === 'PASS';
		this.tests.replaceChildren(Pill(passed ? 'passed' : 'failed', passed ? 'success' : 'error'));
		this.testsNote.textContent = tests.lastRunAt ? `Finished ${tests.lastRunAt.replace('T', ' ').slice(0, 19)}` : '';
	}

	_renderGit(git) {
		if (git && git.error) {
			this.branch.textContent = 'unavailable';
			this.branchNote.textContent = git.error;
			return;
		}
		this.branch.textContent = (git && git.branch) || 'unknown';
		const ahead = Number(git && git.ahead) || 0;
		const behind = Number(git && git.behind) || 0;
		this.branchNote.textContent = ahead || behind
			? `${ahead} ahead, ${behind} behind`
			: 'in step with the remote';
	}

	_attachEvents() {
		this.element.querySelector('#action-reload').addEventListener('click', () => this._reload());
		this.element.querySelector('#action-exit').addEventListener('click', () => this._exit());
		this.element.querySelector('#action-run-tests').addEventListener('click', () => this._runTests());
		this.element.querySelectorAll('[data-test-severity]').forEach(button =>
			button.addEventListener('click', () => this._sendTestMessage(button.dataset.testSeverity)));
	}

	async _reload() {
		const confirmed = await this.shell.confirm({
			title: 'Reload the suite?',
			message: 'Every AutoHotkey script is closed and started again, this dashboard included. It comes back the next time you open it.',
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

	_runTests() {
		const result = AhkDataService.RunAllTests();
		this.shell.showToast(result.ok
			? 'Test run started - watch the Tests strip above'
			: `Could not start the tests: ${result.error}`);
	}

	_sendTestMessage(severity) {
		const result = AhkDataService.LogTestMessage(severity);
		this.shell.showToast(result.ok
			? `Test ${severity} entry logged`
			: `Could not log the test entry: ${result.error}`);
	}
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
		this.runButton.textContent = running ? 'Running…' : 'Run all tests';

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
			this.status.replaceChildren(Pill('running…', 'info'));
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
			const passed = run.overallStatus === 'PASS';
			row.innerHTML = `
				<td>${escapeHtml(TestsSection.FormatTime(run.timestamp))}</td>
				<td class="severity severity-${passed ? 'success' : 'error'}">${escapeHtml(run.overallStatus)}</td>
				<td>${escapeHtml(TestsSection.FormatDuration(run.durationSeconds))}</td>
			`;
			row.addEventListener('click', () => this._showDetail(run));
			if (run.timestamp === this.selectedTimestamp)
				row.classList.add('selected');
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
		this.tableBody.querySelectorAll('tr').forEach(row =>
			row.classList.toggle('selected', row.dataset.timestamp === run.timestamp));

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
		element.append(name, Pill(passed ? 'passed' : suite.status.toLowerCase(), passed ? 'success' : 'error'));

		const duration = document.createElement('span');
		duration.className = 'muted-text';
		duration.textContent = TestsSection.FormatDuration(suite.durationSeconds);
		element.appendChild(duration);

		if (!passed && suite.output) {
			const copy = document.createElement('button');
			copy.type = 'button';
			copy.className = 'button';
			copy.textContent = '📋 Copy output';
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

	_run() {
		const result = AhkDataService.RunAllTests();
		if (!result.ok) {
			this.shell.showToast(`Could not start the tests: ${result.error}`);
			return;
		}
		this.shell.showToast('Test run started');
		this.refresh();
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

		this.list.replaceChildren(...(state.profiles || []).map(profile => this._card(profile)));
	}

	_card(profile) {
		const card = document.createElement('div');
		card.className = 'card stat';
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
	}

	activate() {
		this.refresh();
	}

	refresh() {
		const processes = AhkDataService.GetProcesses();
		const changed = ProcessesSection.Fingerprint(this.processes) !== ProcessesSection.Fingerprint(processes);
		this.processes = processes;
		// Uptime ticks every second; redrawing the table for that alone would
		// fight the user's scrolling, so only a changed set of processes
		// redraws and the uptime cells are updated in place.
		if (changed)
			this._renderRows();
		else
			this._updateUptimes();
	}

	static Fingerprint(processes) {
		return processes.map(process => `${process.processId}:${process.path}:${process.isMissing || 0}`).sort().join(',');
	}

	_updateUptimes() {
		for (const process of this.processes) {
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

		this.processes
			.slice()
			.sort((a, b) => a.name.localeCompare(b.name))
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
		this.processes = [];
	}
}

// Whether this machine is set up the way the suite expects, and what the
// suite is costing it. Its data is read only while the section is on screen.
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
		this.refresh();
	}

	refresh() {
		this._render(AhkDataService.GetHealth());
	}

	_render(health) {
		this._renderCpu(health.cpu || {});

		const autoHotkey = health.autoHotkey || {};
		this.ahkVersion.textContent = autoHotkey.version ? `v${autoHotkey.version}` : 'unknown';
		this.ahkPath.textContent = autoHotkey.path || '';

		const webView2 = health.webView2 || {};
		const known = webView2.status === 'ok';
		this.webView.replaceChildren(Pill(known ? 'installed' : 'version unknown', known ? 'success' : 'warning'));
		this.webViewNote.textContent = known
			? webView2.version
			: 'This window is rendered by WebView2, so it is installed; its version could not be read.';

		this._renderSecrets(health.secrets || {});

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
		if (cpu.percent === '' || cpu.percent === undefined || cpu.percent === null) {
			this.cpu.replaceChildren(Pill('sampling…', 'neutral'));
			this.cpuNote.textContent = `Measuring ${Count(processes, 'process', 'processes')} over the next second.`;
			return;
		}
		const percent = Number(cpu.percent);
		const busy = percent >= HealthSection.BUSY_PERCENT;
		this.cpu.replaceChildren(Pill(`${percent.toFixed(1)}%`, busy ? 'warning' : 'success'));
		this.cpuNote.textContent = `${Count(processes, 'process', 'processes')} across ${Count(cores, 'core', 'cores')}`
			+ (busy ? ' - something is working hard' : '');
	}

	_renderSecrets(secrets) {
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
		this.secrets.replaceChildren(Pill(labels[state] || state, tones[state] || 'neutral'));
		this.secretsNote.textContent = state === 'missing'
			? 'Start the suite once to create the local secrets file.'
			: `${keysWithValue} of ${catalogKeys} catalog keys have a value on this machine.`;
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
	}
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
