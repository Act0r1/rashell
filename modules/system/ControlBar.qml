import QtQuick
import QtQuick.Controls
import Quickshell
import qs.core

Item {
    id: root
    required property var coordinator
    required property var audioState
    required property var systemState
    required property var controlState
    required property string outputName
    implicitWidth: Theme.compactControlSize
    implicitHeight: Theme.controlHeight

    Button {
        id: button
        anchors.fill: parent
        hoverEnabled: true
        Accessible.name: "Control center"

        contentItem: Text {
            text: "󰒓"
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            readonly property bool active: root.coordinator.opened
                && root.coordinator.activePanelId === "control"
                && root.coordinator.anchorItem === root
            color: active || button.hovered || button.down ? Theme.surfaceRaised : "transparent"
            border.color: active ? Theme.accent : "transparent"
            border.width: 1
            radius: Theme.radius
        }

        onClicked: root.coordinator.toggle(
            "control",
            root,
            "right",
            Quickshell.shellDir + "/modules/system/ControlPanel.qml",
            {
                coordinator: root.coordinator,
                audioState: root.audioState,
                systemState: root.systemState,
                controlState: root.controlState
            }
        )
    }

    Component.onCompleted: coordinator.registerAnchor("control", outputName, root, "right")
    Component.onDestruction: coordinator.unregisterAnchor("control", outputName, root)
}
