import QtQuick
import QtQuick.Controls
import qs.core
import qs.ui

FocusScope {
    id: root

    required property var coordinator
    required property var mediaState
    implicitWidth: 430
    implicitHeight: panel.implicitHeight

    Shortcut {
        sequence: "Esc"
        onActivated: root.coordinator.close("escape")
    }

    PanelFrame {
        id: panel
        width: parent.width
        title: "NOW PLAYING"
        onCloseRequested: root.coordinator.close("close-control")

        Column {
            width: parent.width
            spacing: Theme.spaceLg

            Row {
                width: parent.width
                spacing: Theme.spaceLg

                Rectangle {
                    width: 92
                    height: 92
                    radius: Theme.radius
                    color: Theme.surfaceRaised
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: root.mediaState.artUrl
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: parent.children[0].status !== Image.Ready
                        text: "󰎇"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 34
                    }
                }

                Column {
                    width: parent.parent.width - 92 - parent.spacing
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5

                    Text {
                        width: parent.width
                        text: root.mediaState.title
                        color: Theme.text
                        elide: Text.ElideRight
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontTitle
                        font.bold: true
                    }

                    Text {
                        width: parent.width
                        text: root.mediaState.artist || "Unknown artist"
                        color: Theme.textMuted
                        elide: Text.ElideRight
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                    }

                    Text {
                        width: parent.width
                        text: root.mediaState.album
                        color: Theme.textDisabled
                        elide: Text.ElideRight
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                    }
                }
            }

            Slider {
                width: parent.width
                from: 0
                to: Math.max(1, root.mediaState.length)
                value: root.mediaState.position
                enabled: root.mediaState.length > 0
                onMoved: root.mediaState.seek(value / to)
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.spaceMd

                ActionButton {
                    text: "󰒮"
                    accessibleName: "Previous track"
                    enabled: root.mediaState.player && root.mediaState.player.canGoPrevious
                    onClicked: root.mediaState.previous()
                }
                ActionButton {
                    width: 64
                    text: root.mediaState.playing ? "󰏤" : "󰐊"
                    accessibleName: root.mediaState.playing ? "Pause" : "Play"
                    selected: true
                    onClicked: root.mediaState.playPause()
                }
                ActionButton {
                    text: "󰒭"
                    accessibleName: "Next track"
                    enabled: root.mediaState.player && root.mediaState.player.canGoNext
                    onClicked: root.mediaState.next()
                }
            }
        }
    }
}
