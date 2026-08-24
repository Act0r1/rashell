import QtQuick
import QtQuick.Controls
import Quickshell
import qs.core

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
        Accessible.name: root.state.unread + " unread notifications"

        contentItem: Text {
            id: label
            text: (root.state.doNotDisturb ? "󰂛" : "󰂚") + (root.state.unread > 0 ? " " + root.state.unread : "")
            color: root.state.unread > 0 ? Theme.accent : Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            color: button.hovered || button.down ? Theme.surfaceRaised : "transparent"
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
