import QtQuick
import QtQuick.Controls
import Quickshell
import qs.core

Item {
    id: root
    implicitWidth: Theme.compactControlSize
    implicitHeight: Theme.controlHeight

    Button {
        id: button
        anchors.fill: parent
        hoverEnabled: true
        Accessible.name: "Take screenshot"

        contentItem: Text {
            text: "󰄀"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            color: button.hovered || button.down ? Theme.surfaceRaised : "transparent"
            radius: Theme.radius
        }

        onClicked: Quickshell.execDetached([
            "sh", "-c",
            "mkdir -p \"$HOME/Pictures/Screenshots\"; f=\"$HOME/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png\"; grim \"$f\" && wl-copy < \"$f\""
        ])
    }
}
