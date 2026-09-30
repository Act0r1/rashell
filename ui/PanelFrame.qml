import QtQuick
import qs.core

Rectangle {
    id: frame

    required property string title
    property int contentWidth: 360
    default property alias content: body.data
    signal closeRequested()

    implicitWidth: contentWidth
    implicitHeight: header.height + body.implicitHeight + Theme.panelPadding * 2 + Theme.spaceLg
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

            Text {
                anchors {
                    left: parent.left
                    right: closeButton.left
                    rightMargin: Theme.spaceMd
                    verticalCenter: parent.verticalCenter
                }
                text: frame.title
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontTitle
                font.weight: Font.DemiBold
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

        Column {
            id: body
            width: parent.width
            spacing: Theme.spaceLg
        }
    }
}
