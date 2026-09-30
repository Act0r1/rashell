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
    property bool minimal: false

    signal exitMinimalRequested()

    implicitWidth: clockLabel.implicitWidth + 16
    implicitHeight: minimal ? 26 : Theme.controlHeight

    Button {
        id: button
        anchors.fill: parent
        hoverEnabled: true
        padding: 0
        Accessible.name: "Calendar, " + Qt.formatDateTime(root.state.now, "dddd, dd MMMM yyyy HH:mm:ss")
        Accessible.role: Accessible.Button
        BarToolTip {
            visible: button.hovered && !root.coordinator.opened
            text: Qt.formatDateTime(root.state.now, "dddd, dd MMMM yyyy HH:mm:ss")
                + (root.minimal ? "\nRight-click to restore the full bar" : "")
        }

        contentItem: Text {
            id: clockLabel
            text: Qt.formatDateTime(root.state.now, root.minimal ? "HH:mm" : "HH:mm:ss  ddd, dd MMM")
            color: Theme.text
            style: root.minimal ? Text.Raised : Text.Normal
            styleColor: "#c0000000"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            visible: !root.minimal
            readonly property bool active: root.coordinator.opened
                && root.coordinator.activePanelId === "calendar"
                && root.coordinator.anchorItem === root
            color: active || button.hovered || button.down ? Theme.surfaceRaised : "transparent"
            border.color: button.activeFocus ? Theme.focus : active ? Theme.accent : "transparent"
            border.width: button.activeFocus ? Theme.focusWidth : Theme.borderWidth
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

    MouseArea {
        anchors.fill: parent
        enabled: root.minimal
        acceptedButtons: Qt.RightButton
        onClicked: root.exitMinimalRequested()
    }

    Component.onCompleted: coordinator.registerAnchor("calendar", outputName, root, "center")
    Component.onDestruction: coordinator.unregisterAnchor("calendar", outputName, root)
}
