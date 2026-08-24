import QtQuick
import qs.core

Rectangle {
    id: frame

    required property string title
    property int contentWidth: 360
    default property alias content: body.data
    signal closeRequested()

    implicitWidth: contentWidth
    implicitHeight: header.height + separator.height + body.implicitHeight + Theme.panelPadding * 2 + Theme.spaceLg * 2
    color: Theme.surface
    border.color: Theme.borderInteractive
    border.width: Theme.borderWidth
    radius: Theme.radius

    Column {
        anchors {
            fill: parent
            margins: Theme.panelPadding
        }
        spacing: Theme.spaceLg

        Item {
            id: header
            width: parent.width
            height: Theme.compactControlSize

            Text {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                text: "[ " + frame.title.toUpperCase() + " ]"
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontTitle
                font.bold: true
                font.letterSpacing: 2
            }

            ActionButton {
                anchors.right: parent.right
                width: Theme.compactControlSize
                text: "X"
                accessibleName: "Close " + frame.title
                onClicked: frame.closeRequested()
            }
        }

        Rectangle {
            id: separator
            width: parent.width
            height: Theme.borderWidth
            color: Theme.border
        }

        Column {
            id: body
            width: parent.width
            spacing: Theme.spaceLg
        }
    }
}
