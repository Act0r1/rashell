import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.ui

Scope {
    id: root
    required property var notificationState

    Variants {
        model: Quickshell.screens.length > 0 ? [Quickshell.screens[0]] : []

        delegate: Component {
            PanelWindow {
                required property var modelData
                screen: modelData
                visible: root.notificationState.popupVisible
                implicitWidth: 420
                implicitHeight: Math.max(100, popupContent.implicitHeight + 28)
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                anchors { top: true; right: true }
                margins { top: 58; right: 12 }
                WlrLayershell.namespace: "rashell-notification"
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: notificationActions.replying
                    ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

                Rectangle {
                    anchors.fill: parent
                    color: Theme.surface
                    border.color: Theme.accent
                    border.width: 1
                    radius: Theme.radius

                    HoverHandler {
                        id: popupHover
                        onHoveredChanged: {
                            if (hovered) root.notificationState.holdPopup()
                            else if (!notificationActions.replying) root.notificationState.resumePopup()
                        }
                    }

                    Connections {
                        target: root.notificationState
                        function onLatestChanged() {
                            Qt.callLater(function() {
                                if (popupHover.hovered && root.notificationState.popupVisible) {
                                    root.notificationState.holdPopup()
                                }
                            })
                        }
                    }

                    Column {
                        id: popupContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 14
                        spacing: Theme.spaceSm

                        Column {
                            width: parent.width - closeButton.width - Theme.spaceMd
                            spacing: Theme.spaceSm

                            Text {
                                width: parent.width
                                text: root.notificationState.popupAppName
                                textFormat: Text.PlainText
                                color: Theme.accent
                                elide: Text.ElideRight
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                font.bold: true
                            }
                            Text {
                                width: parent.width
                                text: root.notificationState.popupSummary
                                textFormat: Text.PlainText
                                color: Theme.text
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.bold: true
                            }
                            Text {
                                width: parent.width
                                visible: text !== ""
                                text: root.notificationState.popupBody
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
                            id: notificationActions
                            width: parent.width
                            notification: root.notificationState.latest
                            notificationState: root.notificationState
                            onReplyStarted: root.notificationState.holdPopup()
                            onReplyCancelled: {
                                if (!popupHover.hovered) root.notificationState.resumePopup()
                            }
                            onCompleted: root.notificationState.hidePopup()
                        }
                    }

                    Rectangle {
                        id: timeoutTrack
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: Theme.spaceSm
                        anchors.rightMargin: Theme.spaceSm
                        anchors.bottomMargin: Theme.spaceSm
                        height: 3
                        color: Theme.border
                        radius: height / 2

                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1,
                                root.notificationState.popupProgress))
                            height: parent.height
                            color: Theme.accent
                            radius: parent.radius
                        }
                    }

                    CloseButton {
                        id: closeButton
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 8
                        accessibleName: "Dismiss notification"
                        onClicked: {
                            root.notificationState.dismissNotification(root.notificationState.latest)
                            root.notificationState.hidePopup()
                        }
                    }
                }
            }
        }
    }
}
