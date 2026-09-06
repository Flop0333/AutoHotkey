
document.addEventListener('DOMContentLoaded', () => {
	new TestDashboardView().render();
});

class TestDashboardView {

	static POLL_INTERVAL_MS = 1000; // matches Dashboards/Log Dashboard's own polling cadence

	constructor() {
		this.runs = AhkDataService.GetTestRuns();
		this.selectedTimestamp = null;
		this.isRunning = false;
		this.tableBody = document.querySelector('#run-table tbody');
		this.detailPanel = document.querySelector('#detail-panel');
		this.statusBanner = document.querySelector('#status-banner');
		this.runCount = document.querySelector('#run-count');
		this.runTestsBtn = document.querySelector('#run-tests-btn');
		this.toast = document.querySelector('#toast');
	}

	render() {
		this._attachEvents();
		this._renderRows();
		this._checkStatus();
		setInterval(() => this._checkStatus(), TestDashboardView.POLL_INTERVAL_MS);
	}

	_attachEvents() {
		this.runTestsBtn.addEventListener('click', () => {
			AhkDataService.RunTests();
			// Don't wait for the next poll tick - reflect the running state
			// immediately so the click feels responsive.
			if (!this.isRunning) {
				this.isRunning = true;
				this._enterRunningState();
			}
		});
	}

	// Polls run status (same cadence as Log Dashboard's entry polling) so the
	// UI reflects a run kicked off from here, from the tray menu, or from
	// Tests\Run-Tests.ahk directly.
	_checkStatus() {
		let status;
		try {
			status = AhkDataService.GetStatus();
		} catch (e) {
			return;
		}

		const isRunning = status.status === 'running';

		if (isRunning && !this.isRunning) {
			this.isRunning = true;
			this._enterRunningState();
		} else if (!isRunning && this.isRunning) {
			this.isRunning = false;
			this._exitRunningState(status);
		}
	}

	_enterRunningState() {
		this.runTestsBtn.disabled = true;
		this.runTestsBtn.textContent = 'Running…';
		this.statusBanner.hidden = false;
		this._renderRows();
	}

	_exitRunningState(status) {
		this.runTestsBtn.disabled = false;
		this.runTestsBtn.textContent = 'Run All Tests';
		this.statusBanner.hidden = true;
		this.runs = AhkDataService.GetTestRuns();
		this._renderRows();
		this._selectLatestRun();
		this._showToast(status.lastRunStatus === 'PASS' ? 'All tests passed' : 'Some tests failed');
	}

	_selectLatestRun() {
		const latest = this._sortedRuns()[0];
		if (!latest)
			return;
		const row = [...this.tableBody.querySelectorAll('tr')].find(r => r.dataset.timestamp === latest.timestamp);
		if (row)
			this._showDetail(latest, row);
	}

	_sortedRuns() {
		return [...this.runs].sort((a, b) => b.timestamp.localeCompare(a.timestamp));
	}

	_createPendingRow() {
		const row = document.createElement('tr');
		row.className = 'run-row-pending';
		row.innerHTML = `<td colspan="2"><span class="spinner"></span> Running tests&hellip;</td>`;
		return row;
	}

	_formatTime(timestamp) {
		const date = new Date(timestamp);
		return isNaN(date) ? timestamp : date.toLocaleString();
	}

	_renderRows() {
		const rows = this._sortedRuns();
		this.runCount.textContent = `${rows.length} run${rows.length === 1 ? '' : 's'} this session`
			+ (this.isRunning ? ' · 1 running' : '');
		this.tableBody.innerHTML = '';

		if (this.isRunning)
			this.tableBody.appendChild(this._createPendingRow());

		if (!rows.length) {
			if (!this.isRunning)
				this.tableBody.innerHTML = '<tr><td colspan="2" class="empty-state">No test runs yet this session. Click "Run All Tests" to start one.</td></tr>';
			return;
		}

		rows.forEach(run => {
			const row = document.createElement('tr');
			row.dataset.timestamp = run.timestamp;
			row.innerHTML = `
				<td>${this._escape(this._formatTime(run.timestamp))}</td>
				<td class="result result-${this._escape(run.overallStatus)}">${this._escape(run.overallStatus)}</td>
			`;
			row.addEventListener('click', () => this._showDetail(run, row));
			if (run.timestamp === this.selectedTimestamp)
				row.classList.add('selected');
			this.tableBody.appendChild(row);
		});
	}

	_showDetail(run, row) {
		this.tableBody.querySelectorAll('tr').forEach(r => r.classList.remove('selected'));
		row.classList.add('selected');
		this.selectedTimestamp = run.timestamp;

		const suitesHtml = run.suites.map(suite => `
			<div class="suite">
				<div class="suite-header">
					<h3 class="result-${this._escape(suite.status)}">${this._escape(suite.name)}: ${this._escape(suite.status)}</h3>
					<button class="copy-btn" data-suite="${this._escape(suite.name)}" title="Copy this suite's output">📋 Copy</button>
				</div>
				<pre>${this._escape(suite.output || '(no output)')}</pre>
			</div>
		`).join('');

		this.detailPanel.innerHTML = `
			<div class="detail-header">
				<h2 class="result-${this._escape(run.overallStatus)}">${this._escape(run.overallStatus)} — ${this._escape(this._formatTime(run.timestamp))}</h2>
				<button class="copy-btn" id="copy-run-btn" title="Copy the full run log">📋 Copy All</button>
			</div>
			${suitesHtml}
		`;

		this.detailPanel.querySelector('#copy-run-btn').addEventListener('click', () => {
			this._copyToClipboard(this._formatFullLog(run), 'Full run log copied to clipboard');
		});
		this.detailPanel.querySelectorAll('.copy-btn[data-suite]').forEach(button => {
			button.addEventListener('click', () => {
				const suite = run.suites.find(s => s.name === button.dataset.suite);
				this._copyToClipboard(this._formatSuiteLog(suite), `${suite.name} output copied to clipboard`);
			});
		});
	}

	_formatSuiteLog(suite) {
		return `${suite.name}: ${suite.status}\n${suite.output || '(no output)'}`;
	}

	_formatFullLog(run) {
		const suiteLogs = run.suites.map(s => this._formatSuiteLog(s)).join('\n\n');
		return `Test run ${this._formatTime(run.timestamp)} — ${run.overallStatus}\n\n${suiteLogs}`;
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

	_escape(text) {
		const div = document.createElement('div');
		div.textContent = text ?? '';
		return div.innerHTML;
	}
}
