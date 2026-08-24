import QtQuick
import QtQuick.Controls
import qs.core
import qs.ui

FocusScope {
    id: root
    required property var coordinator
    required property var notificationState
    implicitWidth: 420
    implicitHeight: panel.implicitHeight

    Shortcut { sequence: "Esc"; onActivated: root.coordinator.close("escape") }

    PanelFrame {
        id: panel
        width: parent.width
        title: "NOTIFICATIONS"
        onCloseRequested: root.coordinator.close("close-control")

        Column {
            width: parent.width
            spacing: Theme.spaceMd

            Row {
                width: parent.width
                spacing: Theme.spaceMd
                ActionButton {
                    width: (parent.width - parent.spacing) / 2
                    text: root.notificationState.doNotDisturb ? "DND ON" : "DND OFF"
                    selected: root.notificationState.doNotDisturb
                    accessibleName: "Toggle do not disturb"
                    onClicked: root.notificationState.doNotDisturb = !root.notificationState.doNotDisturb
                }
                ActionButton {
                    width: (parent.width - parent.spacing) / 2
                    text: "CLEAR ALL"
                    accessibleName: "Clear all notifications"
                    enabled: root.notificationState.history.count > 0
                    onClicked: root.notificationState.clear()
                }
            }

            Text {
                visible: root.notificationState.history.count === 0
                width: parent.width
                height: 100
                text: "No notifications"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            ListView {
                width: parent.width
                height: Math.min(440, contentHeight)
                visible: count > 0
                model: root.notificationState.history
                spacing: Theme.spaceMd
                clip: true

                delegate: Rectangle {
                    required property int index
                    required property string appName
                    required property string summary
                    required property string body
                    required property string time
                    width: ListView.view.width
                    height: notificationText.implicitHeight + 24
                    color: Theme.surfaceRaised
                    border.color: Theme.border
                    border.width: 1
                    radius: Theme.radius

                    Column {
                        id: notificationText
                        anchors.left: parent.left
                        anchors.right: closeButton.left
                        anchors.leftMargin: 12
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3
                        Text {
                            width: parent.width
                            text: appName + "  ·  " + time
                            textFormat: Text.PlainText
                            color: Theme.textMuted
                            elide: Text.ElideRight
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                        }
                        Text {
                            width: parent.width
                            text: summary
                            textFormat: Text.PlainText
                            color: Theme.text
                            wrapMode: Text.Wrap
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            font.bold: true
                        }
                        Text {
                            width: parent.width
                            visible: body !== ""
                            text: body
                            textFormat: Text.PlainText
                            color: Theme.textMuted
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                        }
                    }

                    ActionButton {
                        id: closeButton
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.top: parent.top
                        anchors.topMargin: 8
                        width: 30
                        text: "×"
                        accessibleName: "Dismiss notification"
                        onClicked: root.notificationState.dismiss(index)
                    }
                }
            }
        }
    }
}
