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
    implicitWidth: label.implicitWidth + 16
    implicitHeight: Theme.controlHeight

    Button {
        id: button
        anchors.fill: parent
        hoverEnabled: true
        padding: 0
        Accessible.name: root.state.unread + " unread notifications"
            + (root.state.timedDoNotDisturb ? "; popups paused for " + Math.ceil(root.state.remainingSeconds / 60) + " more minutes"
                : root.state.doNotDisturb ? "; popups paused until turned off" : "")

        contentItem: Item {
            Row {
                id: label
                anchors.centerIn: parent
                spacing: 6

                ShellIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: root.state.doNotDisturb ? "bell-off" : "bell"
                    tint: root.state.unread > 0 ? Theme.accent : root.state.doNotDisturb ? Theme.textMuted : Theme.text
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.state.unread > 0
                    text: String(root.state.unread)
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                }
            }
        }
        background: Rectangle {
            readonly property bool active: root.coordinator.opened
                && root.coordinator.activePanelId === "notifications"
                && root.coordinator.anchorItem === root
            color: active || button.hovered || button.down ? Theme.surfaceRaised : "transparent"
            border.color: button.activeFocus ? Theme.focus : active ? Theme.accent : "transparent"
            border.width: button.activeFocus ? Theme.focusWidth : Theme.borderWidth
            radius: Theme.radius
        }
        onClicked: {
            root.state.markRead()
            root.coordinator.toggle(
                "notifications", root, "right",
                Quickshell.shellDir + "/modules/notifications/NotificationPanel.qml",
                { coordinator: root.coordinator, notificationState: root.state }
            )
        }
    }

    Component.onCompleted: coordinator.registerAnchor("notifications", outputName, root, "right")
    Component.onDestruction: coordinator.unregisterAnchor("notifications", outputName, root)
}
