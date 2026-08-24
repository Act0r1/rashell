import QtQuick
import QtQuick.Controls
import Quickshell
import qs.core

Item {
    id: root
    required property var state
    implicitWidth: status.implicitWidth + 16
    implicitHeight: Theme.controlHeight

    Button {
        id: button
        anchors.fill: parent
        hoverEnabled: true
        Accessible.name: "CPU " + root.state.cpuPercent + " percent, memory " + root.state.memoryPercent + " percent"

        contentItem: Text {
            id: status
            text: "󰻠 " + root.state.cpuPercent + "%"
            color: root.state.cpuPercent >= 90 ? Theme.danger : Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            color: button.hovered || button.down ? Theme.surfaceRaised : "transparent"
            radius: Theme.radius
        }

        onClicked: Quickshell.execDetached(["ghostty", "-e", "btop"])
    }
}
