import QtQuick
import QtQuick.Controls
import qs.core
import qs.ui

Item {
    id: root
    required property var state
    implicitWidth: keyboardContent.implicitWidth + 16
    implicitHeight: Theme.controlHeight

    Button {
        id: button
        anchors.fill: parent
        hoverEnabled: true
        padding: 0
        Accessible.name: "Keyboard layout " + root.state.layoutName

        contentItem: Item {
            Row {
                id: keyboardContent
                anchors.centerIn: parent
                spacing: Theme.spaceSm

                ShellIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "keyboard"
                    tint: Theme.textMuted
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.state.shortName
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                }
            }
        }

        background: Rectangle {
            color: button.hovered || button.down ? Theme.surfaceRaised : "transparent"
            border.color: button.activeFocus ? Theme.focus : "transparent"
            border.width: button.activeFocus ? Theme.focusWidth : Theme.borderWidth
            radius: Theme.radius
        }

        onClicked: root.state.cycle()
    }
}
