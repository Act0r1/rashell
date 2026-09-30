import QtQuick
import QtQuick.Controls
import qs.core
import qs.ui

FocusScope {
    id: root

    required property var coordinator
    required property var mediaState

    component MediaIcon: Image {
        id: icon
        required property string pathData
        property color tint: Theme.textMuted
        sourceSize.width: width * 2
        sourceSize.height: height * 2
        source: "data:image/svg+xml;utf8," + encodeURIComponent(
            "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='"
            + tint.toString() + "' stroke-width='1.8' stroke-linecap='round' stroke-linejoin='round'><path d='"
            + pathData + "'/></svg>")
    }

    component PlaybackButton: Button {
        id: control
        required property string pathData
        property bool primary: false
        property string accessibleName: ""
        implicitWidth: primary ? 56 : 48
        implicitHeight: implicitWidth
        padding: 0
        hoverEnabled: true
        Accessible.name: accessibleName
        Accessible.role: Accessible.Button
        ToolTip.visible: hovered
        ToolTip.delay: 450
        ToolTip.text: accessibleName

        contentItem: Item {
            MediaIcon {
                anchors.centerIn: parent
                width: 24
                height: 24
                pathData: control.pathData
                tint: control.primary ? Theme.accent
                    : control.hovered || control.down ? Theme.text : Theme.textMuted
                opacity: control.enabled ? 1 : 0.4
            }
        }

        background: Rectangle {
            radius: width / 2
            color: control.primary ? (control.down ? Theme.selectedPressedSurface : control.hovered ? Theme.selectedHoverSurface : Theme.selectedSurface)
                : control.down ? Theme.pressedSurface : control.hovered ? Theme.hoverSurface : "transparent"
            border.color: control.visualFocus ? Theme.focus : "transparent"
            border.width: control.visualFocus ? Theme.focusWidth : 0
        }
    }

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
        title: "Now playing"
        onCloseRequested: {
            root.mediaState.dismiss()
            root.coordinator.close("close-control")
        }

        Text {
            width: parent.width
            visible: !root.mediaState.available
            text: "Nothing playing"
            color: Theme.textMuted
            horizontalAlignment: Text.AlignHCenter
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
        }

        Rectangle {
            visible: root.mediaState.available
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

                    MediaIcon {
                        anchors.centerIn: parent
                        visible: albumArt.status !== Image.Ready
                        width: 36
                        height: 36
                        pathData: "M9 18V5l12-2v13M9 9l12-2M9 18a3 3 0 1 1-3-3c1.7 0 3 1.3 3 3Zm12-2a3 3 0 1 1-3-3c1.7 0 3 1.3 3 3Z"
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
            visible: root.mediaState.available
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
            visible: root.mediaState.available
            width: parent.width
            height: Theme.borderWidth
            color: Theme.border
        }

        Row {
            visible: root.mediaState.available
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spaceLg

            PlaybackButton {
                id: previousButton

                anchors.verticalCenter: parent.verticalCenter
                pathData: "M5 5v14M19 5 9 12l10 7V5Z"
                accessibleName: "Previous track"
                enabled: root.mediaState.player && root.mediaState.player.canGoPrevious
                KeyNavigation.right: playButton
                onClicked: root.mediaState.previous()
            }

            PlaybackButton {
                id: playButton

                pathData: root.mediaState.playing ? "M9 5v14M15 5v14" : "M8 5.5v13L18 12 8 5.5Z"
                accessibleName: root.mediaState.playing ? "Pause" : "Play"
                primary: true
                KeyNavigation.left: previousButton
                KeyNavigation.right: nextButton
                onClicked: root.mediaState.playPause()
            }

            PlaybackButton {
                id: nextButton

                anchors.verticalCenter: parent.verticalCenter
                pathData: "M19 5v14M5 5l10 7-10 7V5Z"
                accessibleName: "Next track"
                enabled: root.mediaState.player && root.mediaState.player.canGoNext
                KeyNavigation.left: playButton
                onClicked: root.mediaState.next()
            }

        }

    }

}
