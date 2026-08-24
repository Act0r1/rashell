import QtQuick
import Quickshell.Services.Pipewire
import qs.core

Item {
    id: root

    property var manifest: null
    property var pluginRegistry: null
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : true

    implicitWidth: 92
    implicitHeight: Theme.controlHeight

    Rectangle {
        anchors.fill: parent
        color: audioHover.hovered || (panelLoader.item && panelLoader.item.open) ? Theme.surfaceRaised : "transparent"
        border.color: panelLoader.item && panelLoader.item.open ? Theme.accent : "transparent"
        border.width: 1
        radius: Theme.radius

        Row {
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: root.muted ? "MUTE" : "VOL"
                color: root.muted ? Theme.danger : Theme.accentMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                font.bold: true
            }

            Text {
                text: Math.round(root.volume * 100) + "%"
                color: root.muted ? Theme.textMuted : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
            }
        }

        HoverHandler {
            id: audioHover
        }

        TapHandler {
            onTapped: {
                if (panelLoader.item) panelLoader.item.open = !panelLoader.item.open
            }
        }
    }

    Loader {
        id: panelLoader
        active: true
        source: "Panel.qml"

        onLoaded: item.anchorItem = root
    }
}
