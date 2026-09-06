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
	document.getElementById('label-info').textContent = formatCount('info', counts.info ?? 0);
	document.getElementById('label-warning').textContent = formatCount('warning', counts.warning ?? 0);
	document.getElementById('label-error').textContent = formatCount('error', counts.error ?? 0);
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
}

function collapseRow(severity) {
	const row = document.getElementById('row-' + severity);
	if (!row) return;
	row.classList.remove('expanded');
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
