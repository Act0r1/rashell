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
        Accessible.name: root.state.updates + " available updates"

        contentItem: Text {
            id: status
            text: "󰏔" + (root.state.updates > 0 ? " " + root.state.updates : "")
            color: root.state.updates > 0 ? Theme.accent : Theme.textMuted
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

        onClicked: Quickshell.execDetached([
            "ghostty", "-e", "bash", "-lc",
            "echo 'Updating system...'; yay; flatpak update; read -n 1 -p 'Press any key to close'"
        ])
    }
}
