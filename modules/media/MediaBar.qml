import QtQuick
import QtQuick.Controls
import Quickshell
import qs.core

Item {
    id: root

    required property var state
    required property var coordinator
    required property string outputName

    visible: state.available
    implicitWidth: visible ? Math.min(300, mediaRow.implicitWidth + 20) : 0
    implicitHeight: Theme.controlHeight

    Button {
        id: button
        anchors.fill: parent
        hoverEnabled: true
        Accessible.name: root.state.available ? root.state.title + ", " + root.state.artist : "No media"

        contentItem: Row {
            id: mediaRow
            spacing: 7

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.state.playing ? "󰏤" : "󰐊"
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(250, implicitWidth)
                text: root.state.artist ? root.state.title + " · " + root.state.artist : root.state.title
                color: Theme.text
                elide: Text.ElideRight
                maximumLineCount: 1
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
            }
        }

        background: Rectangle {
            readonly property bool active: root.coordinator.opened
                && root.coordinator.activePanelId === "media"
                && root.coordinator.anchorItem === root
            color: active || button.hovered || button.down ? Theme.surfaceRaised : "transparent"
            border.color: active ? Theme.accent : "transparent"
            border.width: 1
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
