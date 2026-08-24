import QtQuick
import QtQuick.Controls
import Quickshell
import qs.core

Item {
    id: root

    required property var state
    required property var coordinator
    required property string outputName

    implicitWidth: 150
    implicitHeight: Theme.controlHeight

    Button {
        id: button
        anchors.fill: parent
        hoverEnabled: true
        Accessible.name: "Calendar, " + Qt.formatDateTime(root.state.now, "dddd, dd MMMM yyyy HH:mm")
        Accessible.role: Accessible.Button

        contentItem: Column {
            spacing: -1

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(root.state.now, "HH:mm")
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontTitle
                font.bold: true
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(root.state.now, "ddd, MMM dd").toUpperCase()
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                font.letterSpacing: 1
            }
        }

        background: Rectangle {
            readonly property bool active: root.coordinator.opened
                && root.coordinator.activePanelId === "calendar"
                && root.coordinator.anchorItem === root
            color: active || button.hovered || button.down ? Theme.surfaceRaised : "transparent"
            border.color: active ? Theme.accent : "transparent"
            border.width: Theme.borderWidth
            radius: Theme.radius
        }

        onClicked: root.coordinator.toggle(
            "calendar",
            root,
            "center",
            Quickshell.shellDir + "/modules/clock/CalendarPanel.qml",
            { coordinator: root.coordinator, clockState: root.state }
        )
    }

    Component.onCompleted: coordinator.registerAnchor("calendar", outputName, root, "center")
    Component.onDestruction: coordinator.unregisterAnchor("calendar", outputName, root)
}
