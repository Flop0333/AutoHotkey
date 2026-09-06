function updateCounts(counts) {
	document.getElementById('count-info').textContent = counts.info ?? 0;
	document.getElementById('count-warning').textContent = counts.warning ?? 0;
	document.getElementById('count-error').textContent = counts.error ?? 0;
}

function expandRow(severity, entry) {
	document.querySelectorAll('.row').forEach(row => row.classList.remove('expanded'));

	const row = document.getElementById('row-' + severity);
	if (!row) return;
	row.classList.add('expanded');

	const detail = document.getElementById('detail-' + severity);
	detail.innerHTML = `
		<div class="detail-script">${escapeHtml(entry.script)}</div>
		<div class="detail-message">${escapeHtml(entry.message)}</div>
	`;
}

function escapeHtml(text) {
	const div = document.createElement('div');
	div.textContent = text ?? '';
	return div.innerHTML;
}

// Expose to window so AHK's ExecuteScript() calls (window.updateCounts / window.expandRow) can reach them.
window.updateCounts = updateCounts;
window.expandRow = expandRow;
