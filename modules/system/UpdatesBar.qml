import QtQuick
import QtQuick.Controls
import Quickshell
import qs.core

Item {
    id: root
    required property var state
    required property var coordinator
    required property string outputName
    implicitWidth: status.implicitWidth + 16
    implicitHeight: Theme.controlHeight

    Button {
        id: button
        anchors.fill: parent
        hoverEnabled: true
        Accessible.name: root.state.updates + " available updates"
        Accessible.role: Accessible.Button

        contentItem: Text {
            id: status
            text: "󰏔" + (root.state.updates > 0 ? " " + root.state.updates : "")
            color: root.state.updates > 0 ? Theme.accent : Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontTitle
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            readonly property bool active: root.coordinator.opened
                && root.coordinator.activePanelId === "updates"
                && root.coordinator.anchorItem === root
            color: active || button.hovered || button.down ? Theme.surfaceRaised : "transparent"
            border.color: active ? Theme.accent : "transparent"
            border.width: Theme.borderWidth
            radius: Theme.radius
        }

        onClicked: root.coordinator.toggle(
            "updates",
            root,
            "right",
            Quickshell.shellDir + "/modules/system/UpdatesPanel.qml",
            { coordinator: root.coordinator, systemState: root.state }
        )
    }

    Component.onCompleted: coordinator.registerAnchor("updates", outputName, root, "right")
    Component.onDestruction: coordinator.unregisterAnchor("updates", outputName, root)
}
