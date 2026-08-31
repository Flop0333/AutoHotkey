#Requires AutoHotkey v2

/**
 * Optional bounded in-memory audit trail for action invocations.
 * Records deliberately exclude arguments, values, messages, and diagnostics.
 */
class ActionLog {
    static _enabled := false
    static _maximumEntries := 100
    static _entries := []

    /** Enables logging and bounds memory usage to the requested entry count. */
    static Configure(enabled := true, maximumEntries := 100) {
        if maximumEntries < 1
            throw ValueError("ActionLog maximumEntries must be at least 1")
        this._enabled := !!enabled
        this._maximumEntries := maximumEntries
        this._Trim()
    }

    /** Records metadata only; arguments, values, and error messages are excluded. */
    static Record(actionId, consumer, status, durationMs) {
        if !this._enabled
            return

        this._entries.Push({
            timestamp: FormatTime(, "yyyy-MM-dd HH:mm:ss"),
            actionId: actionId,
            consumer: consumer = "" ? "unknown" : consumer,
            status: status,
            durationMs: durationMs
        })
        this._Trim()
    }

    /** Returns clones so callers cannot mutate the internal history. */
    static GetEntries() {
        entries := []
        for entry in this._entries
            entries.Push(entry.Clone())
        return entries
    }

    /** Removes all entries without changing the logging configuration. */
    static Clear() => this._entries := []

    /** Indicates whether Record() currently stores entries. */
    static Enabled {
        get => this._enabled
    }

    /** Discards the oldest entries when the configured limit is exceeded. */
    static _Trim() {
        while this._entries.Length > this._maximumEntries
            this._entries.RemoveAt(1)
    }
}
