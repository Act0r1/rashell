import QtQuick
import QtQuick.Controls
import Quickshell
import qs.core

Item {
    id: root

    required property var coordinator
    required property string outputName

    readonly property int connectedCount: BluetoothState.connectedDevices.length
    readonly property var firstConnectedDevice: connectedCount > 0 ? BluetoothState.connectedDevices[0] : null
    readonly property string deviceText: firstConnectedDevice
        ? BluetoothState.deviceLabel(firstConnectedDevice) + (connectedCount > 1 ? " +" + (connectedCount - 1) : "")
        : ""

    implicitWidth: Math.min(190, label.implicitWidth + 16)
    implicitHeight: Theme.controlHeight

    Button {
        id: button
        anchors.fill: parent
        hoverEnabled: true
        Accessible.name: !BluetoothState.available ? "Bluetooth unavailable"
            : !BluetoothState.enabled ? "Bluetooth disabled"
            : root.connectedCount > 0 ? "Bluetooth connected to " + root.deviceText
            : "Bluetooth enabled"
        Accessible.role: Accessible.Button

        contentItem: Text {
            id: label
            text: !BluetoothState.enabled ? "󰂲"
                : root.connectedCount > 0 ? "󰂱  " + root.deviceText : "󰂯"
            color: !BluetoothState.available ? Theme.textDisabled
                : root.connectedCount > 0 ? Theme.accent : Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontTitle
            font.bold: root.connectedCount > 0
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            readonly property bool active: root.coordinator.opened
                && root.coordinator.activePanelId === "bluetooth"
                && root.coordinator.anchorItem === root
            color: active || button.hovered || button.down ? Theme.surfaceRaised : "transparent"
            border.color: active ? Theme.accent : "transparent"
            border.width: Theme.borderWidth
            radius: Theme.radius
        }

        onClicked: root.coordinator.toggle(
            "bluetooth",
            root,
            "right",
            Quickshell.shellDir + "/modules/system/BluetoothPanel.qml",
            { coordinator: root.coordinator }
        )
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: BluetoothState.toggleEnabled()
    }

    Component.onCompleted: coordinator.registerAnchor("bluetooth", outputName, root, "right")
    Component.onDestruction: coordinator.unregisterAnchor("bluetooth", outputName, root)
}
