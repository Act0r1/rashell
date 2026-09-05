import QtQuick
import QtQuick.Controls
import qs.core
import qs.ui

FocusScope {
    id: root

    required property var coordinator
    required property var mediaState

    function formatTime(seconds) {
        const total = Math.max(0, Math.floor(Number(seconds) || 0));
        const minutes = Math.floor(total / 60);
        const remaining = total % 60;
        return minutes + ":" + String(remaining).padStart(2, "0");
    }

    implicitWidth: panel.implicitWidth
    implicitHeight: panel.implicitHeight

    Shortcut {
        sequence: "Esc"
        onActivated: root.coordinator.close("escape")
    }

    Timer {
        interval: 1000
        running: root.mediaState.playing && !progress.pressed
        repeat: true
        onTriggered: {
            if (root.mediaState.player) root.mediaState.player.positionChanged()
        }
    }

    PanelFrame {
        id: panel

        anchors.fill: parent
        contentWidth: 480
        title: "NOW PLAYING"
        onCloseRequested: root.coordinator.close("close-control")

        Rectangle {
            width: parent.width
            height: 156
            color: Theme.surfaceRaised
            border.color: Theme.border
            border.width: Theme.borderWidth
            radius: Theme.radius

            Row {
                spacing: Theme.spaceXl

                anchors {
                    fill: parent
                    margins: Theme.spaceLg
                }

                Rectangle {
                    width: 132
                    height: 132
                    color: Theme.background
                    border.color: Theme.borderInteractive
                    border.width: Theme.borderWidth
                    radius: Theme.radius
                    clip: true

                    Image {
                        id: albumArt

                        anchors.fill: parent
                        source: root.mediaState.artUrl
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: albumArt.status !== Image.Ready
                        text: "󰎇"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 40
                    }

                }

                Column {
                    width: parent.width - 132 - parent.spacing
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spaceMd

                    Rectangle {
                        width: playbackState.implicitWidth + Theme.spaceLg * 2
                        height: 24
                        color: "transparent"
                        border.color: Theme.accent
                        border.width: Theme.borderWidth
                        radius: Theme.radius

                        Text {
                            id: playbackState

                            anchors.centerIn: parent
                            text: root.mediaState.playing ? "PLAYING" : "PAUSED"
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            font.bold: true
                            font.letterSpacing: 1
                        }

                    }

                    Text {
                        width: parent.width
                        text: root.mediaState.title || "Unknown track"
                        color: Theme.text
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontTitle + 4
                        font.bold: true
                    }

                    Text {
                        width: parent.width
                        text: root.mediaState.artist || "Unknown artist"
                        color: Theme.textMuted
                        elide: Text.ElideRight
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                        font.bold: true
                    }

                    Text {
                        width: parent.width
                        visible: text.length > 0
                        text: root.mediaState.album
                        color: Theme.textDisabled
                        elide: Text.ElideRight
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                    }

                }

            }

        }

        Column {
            width: parent.width
            spacing: Theme.spaceSm

            LevelSlider {
                id: progress

                width: parent.width
                height: Theme.compactControlSize
                from: 0
                to: Math.max(1, root.mediaState.length)
                stepSize: 1
                value: root.mediaState.position
                enabled: root.mediaState.player && root.mediaState.player.canSeek && root.mediaState.length > 0
                accessibleName: "Track position"
                accessibleDescription: root.formatTime(value) + " of " + root.formatTime(to)
                opacity: enabled ? 1 : 0.55
                onPressedChanged: {
                    if (!pressed) root.mediaState.seek(value / to)
                }
            }

            Item {
                width: parent.width
                height: elapsed.implicitHeight

                Text {
                    id: elapsed

                    anchors.left: parent.left
                    text: root.formatTime(root.mediaState.position)
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                }

                Text {
                    anchors.right: parent.right
                    text: root.formatTime(root.mediaState.length)
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                }

            }

        }

        Rectangle {
            width: parent.width
            height: Theme.borderWidth
            color: Theme.border
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spaceLg

            ActionButton {
                id: previousButton

                width: 48
                height: 42
                text: "󰒮"
                accessibleName: "Previous track"
                enabled: root.mediaState.player && root.mediaState.player.canGoPrevious
                KeyNavigation.right: playButton
                onClicked: root.mediaState.previous()
            }

            ActionButton {
                id: playButton

                width: 60
                height: 46
                text: root.mediaState.playing ? "󰏤" : "󰐊"
                accessibleName: root.mediaState.playing ? "Pause" : "Play"
                selected: true
                KeyNavigation.left: previousButton
                KeyNavigation.right: nextButton
                onClicked: root.mediaState.playPause()
            }

            ActionButton {
                id: nextButton

                width: 48
                height: 42
                text: "󰒭"
                accessibleName: "Next track"
                enabled: root.mediaState.player && root.mediaState.player.canGoNext
                KeyNavigation.left: playButton
                onClicked: root.mediaState.next()
            }

        }

    }

}
