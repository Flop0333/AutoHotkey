#Requires AutoHotkey v2

/** Shows non-modal user messages without treating them as error records. */
class Notifier {
    static Info(message, title := "AutoHotkey", seconds := 5) {
        return this.Show(message, title, "info", seconds)
    }

    static Warning(message, title := "AutoHotkey", seconds := 5) {
        return this.Show(message, title, "warning", seconds)
    }

    static Error(message, title := "AutoHotkey", seconds := 5) {
        return this.Show(message, title, "error", seconds)
    }

    static Show(message, title := "AutoHotkey", severity := "info", seconds := 5) {
        try {
            TrayTip(message, title, this._GetTrayTipOptions(severity))
            if seconds > 0
                SetTimer((*) => TrayTip(), -seconds * 1000)
            return {ok: true}
        } catch Any {
            ; Optional UI must never interrupt its caller.
            return {ok: false}
        }
    }

    static _GetTrayTipOptions(severity) {
        switch StrLower(severity) {
            case "warning":
                return 2
            case "error", "critical":
                return 3
            default:
                return 1
        }
    }
}
