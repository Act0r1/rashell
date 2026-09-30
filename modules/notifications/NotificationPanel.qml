import QtQuick
import QtQuick.Controls
import Quickshell
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
        title: "Notifications"
        onCloseRequested: root.coordinator.close("close-control")

        Column {
            width: parent.width
            spacing: Theme.spaceMd

            Row {
                width: parent.width
                spacing: Theme.spaceMd

                ActionButton {
                    width: parent.width - clearButton.width - parent.spacing
                    text: root.notificationState.timedDoNotDisturb
                        ? "Paused · " + Math.ceil(root.notificationState.remainingSeconds / 60) + " min left"
                        : root.notificationState.doNotDisturb ? "Popups paused" : "Do not disturb"
                    selected: root.notificationState.doNotDisturb
                    subtleSelected: true
                    accessibleName: "Do not disturb settings and timer"
                    onClicked: root.coordinator.open(
                        "dnd", root.coordinator.anchorItem, root.coordinator.alignment,
                        Quickshell.shellDir + "/modules/notifications/DoNotDisturbPanel.qml",
                        { coordinator: root.coordinator, notificationState: root.notificationState }
                    )
                }

                ActionButton {
                    id: clearButton
                    width: 96
                    text: "Clear all"
                    accessibleName: "Clear notification history"
                    flat: true
                    enabled: root.notificationState.history.count > 0
                    onClicked: root.notificationState.clear()
                }
            }

            Row {
                width: parent.width
                spacing: Theme.spaceMd

                Text {
                    width: parent.width - decreaseDuration.width - durationLabel.width
                        - increaseDuration.width - parent.spacing * 3
                    height: Theme.controlHeight
                    text: "POPUP TIME"
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    verticalAlignment: Text.AlignVCenter
                }
                ActionButton {
                    id: decreaseDuration
                    width: Theme.controlHeight
                    text: "−"
                    accessibleName: "Decrease notification popup duration"
                    enabled: root.notificationState.popupDurationSeconds > 1
                    onClicked: root.notificationState.setPopupDurationSeconds(
                        root.notificationState.popupDurationSeconds - 1)
                }
                Text {
                    id: durationLabel
                    width: 64
                    height: Theme.controlHeight
                    text: root.notificationState.popupDurationSeconds + " SEC"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                ActionButton {
                    id: increaseDuration
                    width: Theme.controlHeight
                    text: "+"
                    accessibleName: "Increase notification popup duration"
                    enabled: root.notificationState.popupDurationSeconds < 60
                    onClicked: root.notificationState.setPopupDurationSeconds(
                        root.notificationState.popupDurationSeconds + 1)
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
                    id: notificationCard
                    required property int index
                    required property var notification
                    required property string appName
                    required property string summary
                    required property string body
                    required property string time
                    width: ListView.view.width
                    height: Math.max(notificationContent.implicitHeight + 24, closeButton.height + 16)
                    color: Theme.surfaceRaised
                    border.color: Theme.border
                    border.width: 1
                    radius: Theme.radius

                    Column {
                        id: notificationContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 12
                        spacing: Theme.spaceSm

                        Column {
                            width: parent.width - closeButton.width - Theme.spaceMd
                            spacing: Theme.spaceSm

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
                        NotificationActions {
                            width: parent.width
                            notification: notificationCard.notification
                            notificationState: root.notificationState
                        }
                    }

                    CloseButton {
                        id: closeButton
                        compact: true
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.top: parent.top
                        anchors.topMargin: 8
                        accessibleName: "Dismiss notification"
                        onClicked: root.notificationState.dismiss(index)
                    }
                }
            }
        }
    }
}
