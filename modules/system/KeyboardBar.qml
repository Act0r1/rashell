import QtQuick
import QtQuick.Controls
import qs.core

Item {
    id: root
    required property var state
    implicitWidth: keyboardContent.implicitWidth + 18
    implicitHeight: Theme.controlHeight

    Button {
        id: button
        anchors.fill: parent
        hoverEnabled: true
        Accessible.name: "Keyboard layout " + root.state.layoutName

        contentItem: Row {
            id: keyboardContent
            spacing: Theme.spaceSm

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰌌"
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontTitle
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.state.shortName
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontTitle
            }
        }

        background: Rectangle {
            color: button.hovered || button.down ? Theme.surfaceRaised : "transparent"
            radius: Theme.radius
        }

        onClicked: root.state.cycle()
    }
}
