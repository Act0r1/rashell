import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Scope {
    id: state

    readonly property var players: Mpris.players && Mpris.players.values ? Mpris.players.values : []
    readonly property var player: selectPlayer()
    readonly property bool available: player !== null
    readonly property bool playing: available && player.playbackState === MprisPlaybackState.Playing
    readonly property string title: available ? String(player.trackTitle || "Unknown track") : ""
    readonly property string artist: available ? String(player.trackArtist || "") : ""
    readonly property string album: available ? String(player.trackAlbum || "") : ""
    readonly property string artUrl: available ? String(player.trackArtUrl || "") : ""
    readonly property real length: available && player.length < 922337203685 ? Number(player.length || 0) : 0
    readonly property real position: available ? Number(player.position || 0) : 0

    function selectPlayer() {
        let fallback = null
        for (let index = 0; index < players.length; index++) {
            const candidate = players[index]
            if (!candidate || !candidate.canControl) continue
            if (!fallback) fallback = candidate
            if (candidate.playbackState === MprisPlaybackState.Playing) return candidate
        }
        return fallback
    }

    function playPause() {
        if (!player) return
        if (playing && player.canPause) player.pause()
        else if (player.canPlay) player.play()
    }

    function previous() {
        if (player && player.canGoPrevious) player.previous()
    }

    function next() {
        if (player && player.canGoNext) player.next()
    }

    function seek(ratio) {
        if (!player || !player.canSeek || length <= 0) return
        player.position = Math.max(0, Math.min(length, length * ratio))
    }
}
