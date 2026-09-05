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
        Accessible.name: "System monitor, CPU " + root.state.cpuPercent + " percent, memory " + root.state.memoryPercent + " percent"
        Accessible.role: Accessible.Button

        contentItem: Text {
            id: status
            text: "󰻠"
            color: root.state.cpuPercent >= 90 ? Theme.danger : Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontTitle
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            readonly property bool active: root.coordinator.opened
                && root.coordinator.activePanelId === "system"
                && root.coordinator.anchorItem === root
            color: active || button.hovered || button.down ? Theme.surfaceRaised : "transparent"
            border.color: active ? Theme.accent : "transparent"
            border.width: Theme.borderWidth
            radius: Theme.radius
        }

        onClicked: root.coordinator.toggle(
            "system",
            root,
            "right",
            Quickshell.shellDir + "/modules/system/SystemPanel.qml",
            { coordinator: root.coordinator, systemState: root.state }
        )
    }

    Component.onCompleted: coordinator.registerAnchor("system", outputName, root, "right")
    Component.onDestruction: coordinator.unregisterAnchor("system", outputName, root)
}
