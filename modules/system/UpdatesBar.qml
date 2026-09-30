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
    implicitWidth: status.implicitWidth + 16
    implicitHeight: Theme.controlHeight

    Button {
        id: button
        anchors.fill: parent
        hoverEnabled: true
        padding: 0
        Accessible.name: root.state.updatesRefreshing ? "Checking repository updates"
            : root.state.updatesError ? "Update check failed: " + root.state.updatesError
            : root.state.updates + " repository updates available"
        Accessible.role: Accessible.Button

        contentItem: Item {
            Row {
                id: status
                anchors.centerIn: parent
                spacing: 6

                ShellIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: root.state.updatesRefreshing ? "rotate-cw" : "download"
                    tint: root.state.updatesError ? Theme.danger
                        : root.state.updates > 0 ? Theme.text : Theme.textMuted
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.state.updatesError !== "" || root.state.updates > 0
                    text: root.state.updatesError ? "!" : String(root.state.updates)
                    color: root.state.updatesError ? Theme.danger : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                }
            }
        }

        background: Rectangle {
            readonly property bool active: root.coordinator.opened
                && root.coordinator.activePanelId === "updates"
                && root.coordinator.anchorItem === root
            color: active || button.hovered || button.down ? Theme.surfaceRaised : "transparent"
            border.color: button.activeFocus ? Theme.focus : active ? Theme.accent : "transparent"
            border.width: button.activeFocus ? Theme.focusWidth : Theme.borderWidth
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
