import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Scope {
    id: artwork

    required property MprisPlayer player
    property MprisPlayer cachedPlayer: null
    property string cachedKey: ""
    property string cachedSource: ""
    property string cachedUrl: ""
    readonly property var request: {
        if (!player) return { key: "", source: "" }
        const metadata = player.metadata
        return {
            key: JSON.stringify([
                metadata["mpris:trackid"] || "", metadata["xesam:title"] || "",
                metadata["xesam:artist"] || [], metadata["xesam:album"] || "",
                metadata["xesam:url"] || ""
            ]),
            source: String(metadata["mpris:artUrl"] || "")
        }
    }
    readonly property string url: player && player === cachedPlayer && request.key === cachedKey
        ? cachedUrl || request.source : request.source

    onRequestChanged: capture()

    function capture() {
        if (!player) {
            cachedPlayer = null
            cachedKey = ""
            cachedSource = ""
            cachedUrl = ""
            imageFile.path = ""
            return
        }
        if (!request.source) return
        if (cachedPlayer === player && cachedKey === request.key && cachedSource === request.source) return
        if (request.source.startsWith("file:///") || request.source.startsWith("file://localhost/")) {
            imageFile.requestedPlayer = player
            imageFile.requestedKey = request.key
            imageFile.requestedSource = request.source
            const path = decodeURIComponent(request.source.replace(/^file:\/\/(?:localhost)?/, ""))
            if (imageFile.path === path) imageFile.reload()
            else imageFile.path = path
        } else {
            imageFile.path = ""
            remember(player, request.key, request.source, request.source)
        }
    }

    function remember(sourcePlayer: MprisPlayer, key: string, source: string, imageUrl: string) {
        if (sourcePlayer !== player || key !== request.key) return
        cachedPlayer = sourcePlayer
        cachedKey = key
        cachedSource = source
        cachedUrl = imageUrl
    }

    FileView {
        id: imageFile
        property MprisPlayer requestedPlayer: null
        property string requestedKey: ""
        property string requestedSource: ""
        preload: true
        printErrors: false
        onLoaded: {
            if (requestedPlayer !== artwork.player || requestedKey !== artwork.request.key) return
            const bytes = new Uint8Array(Qt.btoa(data()))
            if (bytes.length === 0) return
            let encoded = ""
            for (let offset = 0; offset < bytes.length; offset += 8192) {
                encoded += String.fromCharCode.apply(null, Array.from(bytes.subarray(offset, offset + 8192)))
            }
            artwork.remember(requestedPlayer, requestedKey, requestedSource,
                "data:application/octet-stream;base64," + encoded)
        }
    }
}
