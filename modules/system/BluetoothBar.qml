import QtQuick
import QtQuick.Controls
import Quickshell
import qs.core
import qs.ui

Item {
    id: root

    required property var coordinator
    required property string outputName

    readonly property int connectedCount: BluetoothState.connectedDevices.length
    readonly property string deviceText: BluetoothState.connectedDevices.map(function(device) {
        return BluetoothState.deviceLabel(device)
    }).join(", ")

    implicitWidth: Math.max(Theme.compactControlSize, label.implicitWidth + 16)
    implicitHeight: Theme.controlHeight

    Button {
        id: button
        anchors.fill: parent
        hoverEnabled: true
        padding: 0
        Accessible.name: !BluetoothState.available ? "Bluetooth unavailable"
            : !BluetoothState.enabled ? "Bluetooth disabled"
            : root.connectedCount > 0 ? "Bluetooth connected to " + root.deviceText
            : "Bluetooth enabled"
        Accessible.role: Accessible.Button

        contentItem: Item {
            Row {
                id: label
                anchors.centerIn: parent
                spacing: 6

                ShellIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "bluetooth"
                    tint: !BluetoothState.available ? Theme.textDisabled
                        : root.connectedCount > 0 ? Theme.text : Theme.textMuted
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.connectedCount > 1
                    text: String(root.connectedCount)
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    elide: Text.ElideRight
                }
            }
        }

        background: Rectangle {
            readonly property bool active: root.coordinator.opened
                && root.coordinator.activePanelId === "bluetooth"
                && root.coordinator.anchorItem === root
            color: active || button.hovered || button.down ? Theme.surfaceRaised : "transparent"
            border.color: button.activeFocus ? Theme.focus : active ? Theme.accent : "transparent"
            border.width: button.activeFocus ? Theme.focusWidth : Theme.borderWidth
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
