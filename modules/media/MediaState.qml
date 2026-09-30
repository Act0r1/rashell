import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Scope {
    id: state

    property MprisPlayer retainedPlayer: null
    property string retainedTrackKey: ""
    readonly property var players: Mpris.players && Mpris.players.values ? Mpris.players.values : []
    readonly property MprisPlayer activePlayer: selectPlayer()
    readonly property string activeTrackKey: trackKey(activePlayer)
    readonly property MprisPlayer player: activePlayer || (
        retainedPlayer && players.indexOf(retainedPlayer) !== -1 && retainedPlayer.canControl
        && retainedPlayer.playbackState === MprisPlaybackState.Paused
        && trackKey(retainedPlayer) === retainedTrackKey ? retainedPlayer : null)
    readonly property bool available: player !== null
    readonly property bool playing: available && player.playbackState === MprisPlaybackState.Playing
    readonly property string title: available ? String(player.trackTitle || "Unknown track") : ""
    readonly property string artist: available ? String(player.trackArtist || "") : ""
    readonly property string album: available ? String(player.trackAlbum || "") : ""
    readonly property string artUrl: artwork.url
    readonly property real length: available && player.length < 922337203685 ? Number(player.length || 0) : 0
    readonly property real position: available ? Number(player.position || 0) : 0

    onActivePlayerChanged: rememberActivePlayer()
    onActiveTrackKeyChanged: rememberActivePlayer()

    MediaArtwork {
        id: artwork
        player: state.player
    }

    Timer {
        id: retainTimer
        interval: 250
        onTriggered: state.retainActivePlayer()
    }

    function trackKey(candidate: MprisPlayer): string {
        return candidate ? JSON.stringify([
            candidate.metadata["mpris:trackid"] || "", candidate.trackTitle || ""
        ]) : ""
    }

    function rememberActivePlayer() {
        retainTimer.stop()
        if (!activePlayer) return
        if (retainedPlayer && retainedPlayer !== activePlayer
            && retainedPlayer.playbackState === MprisPlaybackState.Paused
            && metadataScore(activePlayer) < metadataScore(retainedPlayer)) {
            retainTimer.start()
            return
        }
        retainActivePlayer()
    }

    function retainActivePlayer() {
        if (!activePlayer) return
        retainedPlayer = activePlayer
        retainedTrackKey = trackKey(activePlayer)
    }

    function dismiss() {
        if (activePlayer) return
        retainedPlayer = null
        retainedTrackKey = ""
    }

    function metadataScore(candidate: MprisPlayer): int {
        return (String(candidate.trackTitle || "").trim() ? 2 : 0)
            + (String(candidate.trackArtist || "").trim() ? 4 : 0)
            + (String(candidate.trackAlbum || "").trim() ? 1 : 0)
    }

    function selectPlayer() {
        let selected = null
        let selectedScore = -1
        for (let index = 0; index < players.length; index++) {
            const candidate = players[index]
            if (!candidate || !candidate.canControl) continue
            if (candidate.playbackState !== MprisPlaybackState.Playing) continue
            const score = metadataScore(candidate)
            if (score > selectedScore) {
                selected = candidate
                selectedScore = score
            }
        }
        return selected
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
