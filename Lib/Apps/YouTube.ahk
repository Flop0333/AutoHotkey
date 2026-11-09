; ============================================================================
; === YouTube - Play a video fullscreen, optionally muted =====================
; ============================================================================
;
; [HOW]
;   - Opens the normal watch page in a new browser window (the embed player
;     refuses to play outside a real web page: "Error 153").
;   - Mutes and starts the video through the page's own player API
;     (movie_player.mute()/playVideo()), executed with UIA_Browser's
;     JSExecute. Unlike the "m" shortcut this always ends muted.
;   - Fullscreen uses YouTube's "f" shortcut: the browser only allows
;     fullscreen after a real key press.
;
; [USAGE]
;   YouTube.PlayFullscreen("RDfjXj5EGqI", 17102, true) ; start at 4:45:02, muted
; ============================================================================

#Include Browser.ahk
#Include ..\Tools\UIA-v2\Lib\UIA.ahk
#Include ..\Tools\UIA-v2\Lib\UIA_Browser.ahk
#Include ..\Tools\Info.ahk

class YouTube {
    static WatchUrl(videoId, startSeconds := 0)
        => "https://www.youtube.com/watch?v=" videoId "&t=" startSeconds "s" ; t=0s avoids resuming where YouTube last stopped

    static PlayFullscreen(videoId, startSeconds := 0, muted := false) {
        if !(hwnd := Browser.OpenNewWindow(this.WatchUrl(videoId, startSeconds))) {
            Info("YouTube venster niet gevonden", 5000)
            return false
        }
        if !this._WaitForWatchPage(hwnd) {
            Info("YouTube pagina laadde niet op tijd", 5000)
            return false
        }

        browserUia := UIA_Browser("ahk_id " hwnd)
        browserUia.JSExecute(this._PlayerScript(muted))

        ; "f" is ignored while the player is still loading, so wait for the
        ; script to report playback (a timeout still tries fullscreen).
        this._WaitForTitle(hwnd, this.readyMarker)

        ; Hand the keyboard back from the address bar to the page, then use
        ; YouTube's own fullscreen shortcut.
        WinActivate(hwnd)
        WinWaitActive(hwnd, , 3)
        try ControlFocus("Chrome_RenderWidgetHostHWND1", hwnd)
        Sleep(300)
        Send("f")
        return true
    }

    static readyMarker := "[ahk-ready]"

    ; The video title replaces the plain "YouTube" title once the watch page
    ; has loaded; running JavaScript earlier would hit the previous page.
    static _WaitForWatchPage(hwnd) => this._WaitForTitle(hwnd, " - YouTube")

    static _WaitForTitle(hwnd, text, timeoutMs := 20000) {
        deadline := A_TickCount + timeoutMs
        while (A_TickCount < deadline) {
            try {
                if InStr(WinGetTitle(hwnd), text)
                    return true
            } catch
                return false ; window closed
            Sleep(250)
        }
        return false
    }

    ; Waits for the player API, (mutes and) starts playback, then flags "playing"
    ; to AutoHotkey through the page title, restoring the title shortly after.
    static _PlayerScript(muted) {
        return "(()=>{const end=Date.now()+20000;let started=false;const t=setInterval(()=>{"
            . "const p=document.getElementById('movie_player');"
            . "if(!p||!p.playVideo){if(Date.now()>end)clearInterval(t);return;}"
            . "if(!started){started=true;" (muted ? "p.mute();" : "") "p.playVideo();}"
            . "if(p.getPlayerState()===1||Date.now()>end){clearInterval(t);const o=document.title;"
            . "document.title='" this.readyMarker " '+o;setTimeout(()=>{document.title=o},3000);}"
            . "},250);})();void 0;"
    }
}
