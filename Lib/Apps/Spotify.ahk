#Include App.ahk
#Include ..\Tools\UIA-v2\Lib\UIA.ahk
#Include ..\Tools\Info.ahk

StartSpotifyGoodMorningJazz() => Spotify.StartPlaylist(Playlist.goodMorningJazz)

Class Playlist {
    static goodMorningJazz := "37i9dQZF1DX71VcjjnyaBQ"
}

Class Spotify extends App {
    static __New() => App.Init(
		winTitle := "Spotify",
		ahk_exe := "Spotify.exe"
	)
    
    static StartPlaylist(playlist) {
        Info("Start Spotify playlist", timeout := 8000)

        Spotify.OpenPlaylist(playlist)
        Spotify.PressPlay()
    }

    static OpenPlaylist(playlist) {
        RunWait("spotify:playlist:" playlist) ; Open the playlist
        WinWaitActive("ahk_exe Spotify.exe", "", 10)
    }

    static PressPlay() {
        SpotifyEl := UIA.ElementFromHandle("ahk_exe Spotify.exe")
        playButtonElement := SpotifyEl.WaitElement({Type:50000, Name:"Play Good Morning Jazz"}, timeout := 20000) ; Button Play
        playButtonElement ? playButtonElement.Click() : Info("Spotify control not found (timeout)", timeout := 5000)
    }
}
