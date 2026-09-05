import QtQuick
import QtQuick.Controls
import qs.core
import qs.ui

Item {
    id: root

    required property var notification
    required property var notificationState
    property bool replying: false
    signal replyStarted()
    signal replyCancelled()
    signal completed()

    readonly property var availableActions: notification && notification.actions
        ? notification.actions : []
    readonly property bool hasActions: availableActions.length > 0
    readonly property bool canReply: Boolean(notification && notification.hasInlineReply)

    visible: hasActions || canReply
    implicitHeight: visible ? content.implicitHeight : 0

    function beginReply() {
        replying = true
        replyStarted()
        Qt.callLater(function() { replyField.forceActiveFocus() })
    }

    function submitReply() {
        if (!notificationState.sendReply(notification, replyField.text)) return
        replyField.text = ""
        replying = false
        completed()
    }

    onNotificationChanged: {
        replying = false
        Qt.callLater(function() { replyField.text = "" })
    }

    Column {
        id: content
        width: parent.width
        spacing: Theme.spaceSm

        Flow {
            id: actionFlow
            width: parent.width
            height: childrenRect.height
            visible: root.hasActions || (root.canReply && !root.replying)
            spacing: Theme.spaceSm

            Repeater {
                model: root.availableActions

                delegate: ActionButton {
                    required property var modelData
                    width: Math.min(implicitWidth, actionFlow.width)
                    text: String(modelData.text || modelData.identifier || "Open").toUpperCase()
                    accessibleName: String(modelData.text || "Open notification")
                    onClicked: {
                        root.notificationState.invokeAction(root.notification, modelData)
                        root.completed()
                    }
                }
            }

            ActionButton {
                visible: root.canReply && !root.replying
                text: "REPLY"
                accessibleName: "Reply to notification"
                onClicked: root.beginReply()
            }
        }

        Row {
            width: parent.width
            height: Math.max(Theme.compactControlSize, cancelButton.implicitHeight)
            visible: root.replying
            spacing: Theme.spaceSm

            TextField {
                id: replyField
                width: parent.width - sendButton.width - cancelButton.width - parent.spacing * 2
                height: parent.height
                placeholderText: root.notification && root.notification.inlineReplyPlaceholder
                    ? root.notification.inlineReplyPlaceholder : "Reply…"
                color: Theme.text
                placeholderTextColor: Theme.textMuted
                selectionColor: Theme.accent
                selectedTextColor: Theme.textOnAccent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                leftPadding: Theme.spaceMd
                rightPadding: Theme.spaceMd
                Accessible.name: "Notification reply"
                onAccepted: root.submitReply()

                background: Rectangle {
                    color: Theme.surface
                    border.color: replyField.activeFocus ? Theme.focus : Theme.borderInteractive
                    border.width: replyField.activeFocus ? Theme.focusWidth : Theme.borderWidth
                    radius: Theme.radius
                }
            }

            ActionButton {
                id: sendButton
                anchors.verticalCenter: parent.verticalCenter
                width: implicitWidth
                text: "SEND"
                selected: true
                enabled: replyField.text.trim() !== ""
                accessibleName: "Send reply"
                onClicked: root.submitReply()
            }

            CloseButton {
                id: cancelButton
                anchors.verticalCenter: parent.verticalCenter
                accessibleName: "Cancel reply"
                onClicked: {
                    replyField.text = ""
                    root.replying = false
                    root.replyCancelled()
                }
            }
        }
    }
}
