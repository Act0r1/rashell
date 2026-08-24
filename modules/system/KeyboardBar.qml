import QtQuick
import QtQuick.Controls
import qs.core

Item {
    id: root
    required property var state
    implicitWidth: label.implicitWidth + 18
    implicitHeight: Theme.controlHeight

    Button {
        id: button
        anchors.fill: parent
        hoverEnabled: true
        Accessible.name: "Keyboard layout " + root.state.layoutName

        contentItem: Text {
            id: label
            text: "󰌌 " + root.state.shortName
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            color: button.hovered || button.down ? Theme.surfaceRaised : "transparent"
            radius: Theme.radius
        }

        onClicked: root.state.cycle()
    }
}
