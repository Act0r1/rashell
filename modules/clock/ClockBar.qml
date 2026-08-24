import QtQuick
import QtQuick.Controls
import Quickshell
import qs.core

Item {
    id: root

    required property var state
    required property var coordinator
    required property string outputName

    implicitWidth: clockLabel.implicitWidth + 20
    implicitHeight: Theme.controlHeight

    Button {
        id: button
        anchors.fill: parent
        hoverEnabled: true
        Accessible.name: "Calendar, " + Qt.formatDateTime(root.state.now, "dddd, dd MMMM yyyy HH:mm")
        Accessible.role: Accessible.Button

        contentItem: Text {
            id: clockLabel
            text: Qt.formatDateTime(root.state.now, "HH:mm:ss ddd, MMM dd")
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
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
