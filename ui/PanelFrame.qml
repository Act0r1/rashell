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
    border.color: Theme.border
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
            height: Math.max(Theme.compactControlSize, closeButton.implicitHeight)

            Rectangle {
                id: titleMarker
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                width: 3
                height: 18
                color: Theme.accent
                radius: 1
            }

            Text {
                anchors {
                    left: titleMarker.right
                    right: closeButton.left
                    leftMargin: Theme.spaceMd
                    rightMargin: Theme.spaceMd
                    verticalCenter: parent.verticalCenter
                }
                text: frame.title.toUpperCase()
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontTitle
                font.bold: true
                font.letterSpacing: 1
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            CloseButton {
                id: closeButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
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
