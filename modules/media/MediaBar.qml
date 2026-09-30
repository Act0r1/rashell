import QtQuick
import QtQuick.Controls
import Quickshell
import qs.core
import qs.ui

Item {
    id: root

    required property var state
    required property var coordinator
    required property string outputName

    visible: state.available
    implicitWidth: state.available ? Math.min(220, mediaIcon.implicitWidth + labelMetrics.advanceWidth + Theme.spaceSm + 16) : 0
    implicitHeight: Theme.controlHeight

    TextMetrics {
        id: labelMetrics
        text: mediaLabel.text
        font: mediaLabel.font
    }

    Button {
        id: button
        anchors.fill: parent
        hoverEnabled: true
        padding: 0
        leftPadding: Theme.spaceMd
        rightPadding: Theme.spaceMd
        Accessible.name: root.state.available ? root.state.title + ", " + root.state.artist : "No media"
        BarToolTip {
            visible: button.hovered && !root.coordinator.opened && text !== ""
            text: root.state.artist ? root.state.title + " · " + root.state.artist : root.state.title
        }

        contentItem: Item {
            clip: true

            Row {
                id: mediaRow
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: mediaLabel.width > 0 ? Theme.spaceSm : 0

                Text {
                    id: mediaIcon
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, Math.max(0, button.availableWidth))
                    text: root.state.playing ? "󰏤" : "󰐊"
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontTitle
                }

                Text {
                    id: mediaLabel
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(0, button.availableWidth - mediaIcon.width - Theme.spaceSm)
                    text: root.state.artist ? root.state.title + " · " + root.state.artist : root.state.title
                    color: Theme.text
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                }
            }
        }

        background: Rectangle {
            readonly property bool active: root.coordinator.opened
                && root.coordinator.activePanelId === "media"
                && root.coordinator.anchorItem === root
            color: active || button.hovered || button.down ? Theme.surfaceRaised : "transparent"
            border.color: button.activeFocus ? Theme.focus : active ? Theme.accent : "transparent"
            border.width: button.activeFocus ? Theme.focusWidth : Theme.borderWidth
            radius: Theme.radius
        }

        onClicked: root.coordinator.toggle(
            "media",
            root,
            "center",
            Quickshell.shellDir + "/modules/media/MediaPanel.qml",
            { coordinator: root.coordinator, mediaState: root.state }
        )
    }

    Component.onCompleted: coordinator.registerAnchor("media", outputName, root, "center")
    Component.onDestruction: coordinator.unregisterAnchor("media", outputName, root)
}
