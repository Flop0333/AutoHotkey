; ============================================================================
; === Woonkamer Scene - Tv, jazz and a muted fullscreen video in one go =======
; ============================================================================
;
; Used by the Djengus F5 double tap and the Remote Board.
; ============================================================================

#Include PhilipsTv.ahk
#Include Spotify.ahk
#Include YouTube.ahk

; Spotify goes first: opening the playlist activates its window, which would
; otherwise pull focus away from the fullscreen video.
StartWoonkamerScene() {
    PhilipsTv.On()
    try StartSpotifyGoodMorningJazz()
    YouTube.PlayFullscreen("RDfjXj5EGqI", 0, true) ; from the start, muted
}
