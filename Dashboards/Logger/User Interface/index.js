const SEVERITY_LABELS = {
	info: { singular: 'Info', plural: 'Infos' },
	warning: { singular: 'Warning', plural: 'Warnings' },
	error: { singular: 'Error', plural: 'Errors' },
};

function formatCount(severity, count) {
	const labels = SEVERITY_LABELS[severity];
	const label = count === 1 ? labels.singular : labels.plural;
	return `${count} ${label}`;
}

function updateCounts(counts) {
	for (const severity of ['info', 'warning', 'error']) {
		const count = counts[severity] ?? 0;
		const row = document.getElementById('row-' + severity);
		document.getElementById('label-' + severity).textContent = formatCount(severity, count);
		row.hidden = count < 1;
		if (row.hidden) row.classList.remove('expanded');
	}
	scheduleResize();
}

// Rows expand/collapse independently - info/warning/error can all be
// showing their own latest entry at the same time.
function expandRow(severity, entry) {
	const row = document.getElementById('row-' + severity);
	if (!row) return;
	row.classList.add('expanded');

	const detail = document.getElementById('detail-' + severity);
	detail.innerHTML = `
		<div class="detail-script">${escapeHtml(entry.script)}</div>
		<div class="detail-message">${escapeHtml(entry.message)}</div>
	`;
	scheduleResize();
}

function collapseRow(severity) {
	const row = document.getElementById('row-' + severity);
	if (!row) return;
	row.classList.remove('expanded');
	scheduleResize();
}

function scheduleResize() {
	requestAnimationFrame(() => ahk.Resize(Math.ceil(document.body.getBoundingClientRect().height)));
}

function escapeHtml(text) {
	const div = document.createElement('div');
	div.textContent = text ?? '';
	return div.innerHTML;
}

// Expose to window so AHK's ExecuteScript() calls (window.updateCounts / window.expandRow / window.collapseRow) can reach them.
window.updateCounts = updateCounts;
window.expandRow = expandRow;
window.collapseRow = collapseRow;
